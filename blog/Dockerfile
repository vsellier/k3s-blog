FROM jekyll/jekyll:stable as build

COPY . /src

WORKDIR /src

RUN ls -al && jekyll build 

FROM nginx:stable

COPY --from=build /src/_site/ /usr/share/nginx/html
