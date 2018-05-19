#!/bin/bash

set -x

pushd .;
cd blog
JEKYLL_ENV=production bundle exec jekyll build
popd;

rsync -avh . /var/www --delete
