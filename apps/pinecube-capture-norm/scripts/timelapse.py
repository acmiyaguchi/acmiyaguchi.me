from datetime import datetime
from functools import partial
from multiprocessing import Pool
from pathlib import Path

import click
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import skimage.io as skio
from tqdm import tqdm
from PIL import Image
from skimage import color, draw, exposure, feature, registration, transform
from skimage.util import img_as_float, img_as_ubyte


def crop_circle(img, radius=520, radius_range=1):
    adapted = exposure.equalize_adapthist(img, clip_limit=0.03)
    edges = feature.canny(color.rgb2gray(adapted))

    # 720p: inner pot is around r=302, inner lid is around r=334, outerlid is r=344
    # 1080p: outerlid is r=520, depends on how the camera is handled though
    hough_radii = np.arange(radius, radius + radius_range, 1)
    hough_res = transform.hough_circle(edges, hough_radii)
    accums, cx, cy, radii = transform.hough_circle_peaks(
        hough_res, hough_radii, total_num_peaks=1
    )

    image = np.dstack((img, np.ones(img.shape[:2]).astype(np.uint8) * 255))
    mask = np.zeros(image.shape, dtype=bool)
    cyy, cxx, rr = list(zip(cy, cx, radii))[0]
    mask[draw.disk((cyy, cxx), rr, shape=image.shape)] = 1

    return (image * mask)[cyy - rr : cyy + rr, cxx - rr : cxx + rr]


def do_crop_norm(img):
    # we're doing this work twice unfortunately
    cropped = crop_circle(img, radius=520, radius_range=10)
    adjusted = exposure.equalize_adapthist(cropped, clip_limit=0.03)
    return adjusted


def add_padding(img, x=1100, y=1100):
    canvas = np.zeros((x, y, img.shape[2]))
    h, w = img.shape[:2]
    x_off = (x - w) // 2
    y_off = (y - h) // 2
    canvas[y_off : y_off + h, x_off : x_off + w, :] = img
    return canvas


def do_matched_crop(img, ref):
    # assume our images are going to be roughtly the same size
    # hardcoding is bad though
    # https://scikit-image.org/docs/dev/auto_examples/registration/plot_register_translation.html#sphx-glr-auto-examples-registration-plot-register-translation-py
    pad = 1100
    c = pad // 2
    r = 520
    # resize?
    #     if img.shape[1] > 1040:
    #         img = transform.rescale(img, 1040/img.shape[1])
    img_pad = add_padding(img, pad, pad)
    ref_pad = add_padding(ref, pad, pad)
    edge = lambda x: feature.canny(color.rgb2gray(add_padding(x)))
    (y, x), error, diffphase = registration.phase_cross_correlation(
        edge(ref_pad), edge(img_pad)
    )
    image = np.dstack(
        (img_as_ubyte(img_pad), np.ones(img_pad.shape[:2]).astype(np.uint8) * 255)
    )
    mask = np.zeros(image.shape, dtype=bool)
    mask[draw.disk((c - y, c - x), r, shape=image.shape)] = 1

    return (image * mask)[
        int(c - r - y) : int(c + r - y), int(c - r - x) : int(c + r - x), :
    ]


# # https://stackoverflow.com/a/51219787
def convert_frame(img):
    im = Image.fromarray(img)
    alpha = im.getchannel("A")
    # Convert the image into P mode but only use 255 colors in the palette out of 256
    im = im.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255)
    # Set all pixel values below 128 to 255 , and the rest to 0
    mask = Image.eval(alpha, lambda a: 255 if a <= 128 else 0)
    # Paste the color of index 255 and use alpha as a mask
    im.paste(255, mask)
    # The transparency index is 255
    im.info["transparency"] = 255
    return im

def process_file(path):
    ds_format = "%Y%m%d%H%M"
    labels = ["red", "green", "blue"]
    ds = datetime.strptime(path.name.split(".")[0], ds_format).isoformat()
    img = skio.imread(path)
    res = img.mean(axis=(0, 1))
    return img, dict(ds=ds, **dict(zip(labels, res)))

@click.command()
@click.argument("output", type=click.Path(dir_okay=False))
@click.option(
    "--input-dir",
    type=click.Path(exists=True, file_okay=False),
    default="data/captures_v2",
)
def main(output, input_dir):
    paths = sorted(Path(input_dir).glob("*.jpeg"))

    with Pool() as p:
        res = list(tqdm(p.imap(process_file, paths), total=len(paths)))
    
    images, rgb_data = zip(*res)
    df = pd.DataFrame(rgb_data)
    df["ds"] = pd.to_datetime(df.ds)

    filtered = df[(df.red < 80) & (df.red > 40) & (df.green > 40)].copy()
    filtered["date"] = filtered.ds.dt.floor("d")
    filtered["idx"] = filtered.index
    dates = filtered.groupby("date").min()

    subset = [images[i] for i in dates.idx]
    with Pool() as p:
        adjusted = list(tqdm(p.imap(do_crop_norm, subset), total=len(subset)))
        do_match_against_init = partial(do_matched_crop, ref=adjusted[0])
        shifted = list(
            tqdm(p.imap(do_match_against_init, adjusted), total=len(adjusted))
        )

    convert_frame(shifted[0]).save(
        output,
        save_all=True,
        append_images=[convert_frame(x) for x in shifted[1:]],
        loop=0,
    )


if __name__ == "__main__":
    main()
