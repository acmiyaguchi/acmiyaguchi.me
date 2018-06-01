#!/usr/bin/env python

import click
import requests
import os
import shutil


@click.command()
@click.option('--path', type=click.Path(), required=True)
@click.option('--prefix', type=str)
def main(path, prefix):
    if prefix:
        path = os.path.join(path, prefix)
    os.makedirs(path, exist_ok=True)

    basename = "GSSLOOPS-wcwv-{}.jpg"
    for i in range(1, 11):
        out = os.path.join(path, basename.format(i))
        url = "http://www.goes.noaa.gov/GSSLOOPS/wcwv/{}.jpg".format(i)
        r = requests.get(url, stream=True)
        if r.status_code == 200:
            with open(out, 'wb') as f:
                r.raw_decode_content = True
                shutil.copyfileobj(r.raw, f)


if __name__ == '__main__':
    main()