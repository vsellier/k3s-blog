---
layout: post
title:  "Building the blog's docker image"
date:   2019-11-26 18:21:30 +0100
tags: [docker, docker-hub, raspberry, buildx]
---

## Jekyll

[Jekyll](https://jekyllrb.com/) is a blog engine using markdown files to generate a static blog. It's a very convenient way to start a blog.

Unfortunaltely, the [official jekyll docker image](https://hub.docker.com/r/jekyll/jekyll/tags) is only available for ``linux/amd64`` architectures. This will require us to perfom a little gymnastic to generate the blog and create an image than can be run on an arm platform. The ultime goal is to be able to automatise the image generation when a new content is committed.

The image will be stored on docker hub on this repository : [https://hub.docker.com/repository/docker/vsellier/k3s-blog/](https://hub.docker.com/repository/docker/vsellier/k3s-blog/)

## Testing locally

Before pushing the code, the blog content needs to be tested locally. Jekyll has a mode to run a small web server and monitor the local content change. 
To do so, the official jekyll docker image can be used to avoid to setup a complete ruby environment :

(from [https://github.com/vsellier/k3s-blog/blob/master/run-locally.sh](https://github.com/vsellier/k3s-blog/blob/master/run-locally.sh))

```shell
docker run -ti -v "${PWD}/blog:/src" -w /src \
    -v "${PWD}/build_cache/bundle:/usr/local/bundle" \
    -v "${PWD}/build_cache/jekyll:/home/jekyll/.bundle" \
    -p 4000:4000 --rm --name jekyll \
    jekyll/jekyll:stable jekyll serve --draft ./
```

It generate the ``._site`` directory containing the static files and start the litle web server listening on port 4000.

A volume on ``/usr/local/bundle`` can be mount to cache the ruby libs to don't have to download them each time the container is launched.

The ``--draft`` option is specified to build the blog with the draft posts published.

## Preparing the image for the raspberry

### From the static files

For the beginning, it's possible to generate on a laptop the static files and manually build the docker image for the amr architecture.

If your docker version allows it, you can build an arm image on a ``x64`` docker with the buildx command. if not, you can build the image directly on a raspberry.

You can refer to the complete [multi-arch](https://docs.docker.com/docker-for-mac/multi-arch/) docker documentation for more detailled information.

#### Buildx initialisation

The first time the image is built, the builder needs to be initialised :

```shell
$ docker buildx create --name myblogbuilder
$ docker buildx inspect --bootstrap
```

It will create the builder and download the necessary data.

#### Build the image

```bash
$ docker buildx build --platform linux/arm/v7 -t vsellier/k3s-blog -f Dockerfile-for-static .
```
This command creates an **arm/v7** image directly on a x64 laptop.

It's possible to push it manually ao automaticcaly (with the ``--push`` option) to docker hub. Its

## Generate from A to Z

To be able to create the image from the base on an arm computer, a dedicated jekyll image compatible with the arm arch have to be created.
This will be covered in another post later if needed as it's not blocker with my current development environment.
