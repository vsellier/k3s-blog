#!/bin/bash -x

IMAGE=jekyll/jekyll:stable

docker pull ${IMAGE}

docker volume create gem

docker run -ti --rm -v gem:/usr/gem -v "${PWD}/blog:/src" -w /src -v "${PWD}/build_cache/bundle:/usr/local/bundle" -v "${PWD}/build_cache/jekyll:/home/jekyll/.bundle" -v "$(pwd)/run.sh:/run.sh" -p 4000:4000 --name jekyll --entrypoint /run.sh ${IMAGE}
