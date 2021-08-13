# Update:

For alpine:3.14, PDAL is included in the alpine package sources, so only
```
RUN apk update && apk add pdal
```
is necessary to install PDAL

# PDAL docker image

Repo which contains a Dockerfile to compile [PDAL](https://pdal.io) - Point Data Abstraction Library.
The related docker image is created and available for download from here:

https://hub.docker.com/r/mundialis/docker-pdal

## Background info

This docker image is based on Alpine Linux.

It is build with
```
docker build . -t docker-pdal

```
