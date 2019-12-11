#!/bin/bash

echo "**** Checking if there is a more recent jekyll image..."
docker pull jekyll/jekyll:stable

echo "**** Building the site..."
docker run -ti -v "${PWD}/blog:/src" -w /src -v "${PWD}/build_cache/bundle:/usr/local/bundle" -v "${PWD}/build_cache/jekyll:/home/jekyll/.bundle" -e JEKYLL_ENV=production -p 4000:4000 --rm --name jekyll jekyll/jekyll:stable jekyll build ./

