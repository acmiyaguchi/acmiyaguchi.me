#!/usr/local/env bash

set -x

export JEKYLL_ENV=production

pushd .;
cd blog
jekyll build
popd;

rsync -avh . /var/www --delete
