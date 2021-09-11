import io

import matplotlib.pyplot as plt
import numpy as np
import skimage.io as skio
from flask import Response
from skimage import color, draw, exposure, feature, transform
from skimage.util import img_as_ubyte


def crop_circle(img, radius=520, radius_range=1):
    edges = feature.canny(color.rgb2gray(img))

    # 720p: inner pot is around r=302, inner lid is around r=334, outerlid is r=344
    # 1080p: outerlid is r=520, depends on how the camera is handled though
    hough_radii = np.arange(radius, radius + 1, 1)
    hough_res = transform.hough_circle(edges, hough_radii)
    accums, cx, cy, radii = transform.hough_circle_peaks(
        hough_res, hough_radii, total_num_peaks=1
    )

    image = np.dstack((img, np.ones(img.shape[:2]).astype(np.uint8) * 255))
    mask = np.zeros(image.shape, dtype=bool)
    cyy, cxx, rr = list(zip(cy, cx, radii))[0]
    mask[draw.disk((cyy, cxx), rr, shape=image.shape)] = 1

    return (image * mask)[cyy - rr : cyy + rr, cxx - rr : cxx + rr]


def main(request):
    ds = request.args["ds"]
    url = f"https://storage.googleapis.com/acmiyaguchi/pinecube/captures_v2/{ds}.jpeg"
    img = skio.imread(url)

    # we're doing this work twice unfortunately
    cropped = crop_circle(img, radius=520)
    adjusted = exposure.equalize_adapthist(cropped, clip_limit=0.03)
    output_img = crop_circle(img_as_ubyte(adjusted), radius=520)

    # https://stackoverflow.com/a/50728936
    output = io.BytesIO()
    plt.imsave(output, output_img)
    return Response(output.getvalue(), mimetype="image/png")


if __name__ == "__main__":

    class Request:
        def __init__(self, args):
            self.args = args

    main(Request(dict(ds="202109090300")))
