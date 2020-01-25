#!/bin/bash

IMAGE=jekyll/jekyll:stable

docker pull ${IMAGE}
docker run -ti -v "${PWD}/blog:/src" -w /src -v "${PWD}/build_cache/bundle:/usr/local/bundle" -v "${PWD}/build_cache/jekyll:/home/jekyll/.bundle" -p 4000:4000 --rm --name jekyll ${IMAGE} jekyll serve --draft ./

