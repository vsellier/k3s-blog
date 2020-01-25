#!/bin/bash

IMAGE=jekyll/jekyll:stable

echo "**** Checking if there is a more recent jekyll image..."
docker pull ${IMAGE}

echo "**** Building the site..."
docker run -ti -v "${PWD}/blog:/src" -w /src -v "${PWD}/build_cache/bundle:/usr/local/bundle" -v "${PWD}/build_cache/jekyll:/home/jekyll/.bundle" -e JEKYLL_ENV=production -p 4000:4000 --rm --name jekyll ${IMAGE} jekyll build ./
