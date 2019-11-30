FROM jekyll/jekyll:stable as build

COPY . /src

WORKDIR /src

RUN jekyll build 

FROM nginx/1.16.1

COPY --from=build /src/_site/ /usr/share/nginx/html
