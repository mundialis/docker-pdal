FROM alpine:3.19 as build

LABEL authors="Carmen Tawalika,Markus Neteler"
LABEL maintainer="tawalika@mundialis.de,neteler@mundialis.de"

ARG PDAL_VERSION=2.1.0
ARG LIBGEOTIFF_VERSION=1.5.1
ARG LASZIP_VERSION=3.4.3
ENV NUMTHREADS=4

USER root

ENV BUILD_PKGS="build-base cmake"
ENV LIBGEOTIFF_BUILD_PKGS="tiff-dev proj-dev"
ENV PDAL_BUILD_PKGS="curl-dev gdal-dev geos-dev jsoncpp-dev \
    libexecinfo-dev libunwind-dev libxml2-dev postgresql-dev python3-dev \
    py3-numpy-dev sqlite-dev"
RUN apk update && apk add $BUILD_PKGS $LIBGEOTIFF_BUILD_PKGS $PDAL_BUILD_PKGS
RUN apk add hdf5-dev

# compile libgeotiff
WORKDIR /src
RUN wget -q \
  http://download.osgeo.org/geotiff/libgeotiff/libgeotiff-${LIBGEOTIFF_VERSION}.tar.gz
RUN tar xfz libgeotiff-${LIBGEOTIFF_VERSION}.tar.gz
WORKDIR /src/libgeotiff-${LIBGEOTIFF_VERSION}
RUN ./configure
RUN make

# compile laszip
WORKDIR /src
RUN wget -q https://github.com/LASzip/LASzip/releases/download/$LASZIP_VERSION/laszip-src-$LASZIP_VERSION.tar.gz
RUN tar xfz laszip-src-$LASZIP_VERSION.tar.gz
WORKDIR /src/laszip-src-$LASZIP_VERSION/build
RUN cmake .. && make && make install

# compile pdal
WORKDIR /src
RUN wget -q \
 https://github.com/PDAL/PDAL/releases/download/${PDAL_VERSION}/PDAL-${PDAL_VERSION}-src.tar.gz
RUN tar xfz PDAL-${PDAL_VERSION}-src.tar.gz
WORKDIR PDAL-${PDAL_VERSION}-src/build
RUN cmake .. \
      -G "Unix Makefiles" \
      -DGEOTIFF_INCLUDE_DIR=/src/libgeotiff-${LIBGEOTIFF_VERSION} \
      -DGEOTIFF_LIBRARY=/src/libgeotiff-${LIBGEOTIFF_VERSION} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_C_COMPILER=gcc \
      -DCMAKE_CXX_COMPILER=g++ \
      -DCMAKE_MAKE_PROGRAM=make \
      -DBUILD_PLUGIN_PYTHON=ON \
      -DBUILD_PLUGIN_CPD=OFF \
      -DBUILD_PLUGIN_GREYHOUND=ON \
      -DBUILD_PLUGIN_NITF=OFF \
      -DBUILD_PLUGIN_ICEBRIDGE=ON \
      -DBUILD_PLUGIN_PGPOINTCLOUD=ON \
      -DBUILD_PGPOINTCLOUD_TESTS=OFF \
      -DBUILD_PLUGIN_SQLITE=ON \
      -DWITH_LASZIP=ON \
      -DWITH_LAZPERF=OFF \
      -DWITH_TESTS=ON
RUN make -j $NUMTHREADS
RUN make install

RUN pdal --version
COPY simple.laz simple.laz
RUN pdal info simple.laz


FROM alpine:3.19 as pdal

RUN apk add curl jsoncpp libexecinfo libunwind
RUN apk add gdal geos libxml2 postgresql python3 py3-numpy sqlite

# get PDAL
COPY --from=build /usr/bin/pdal* /usr/bin/
COPY --from=build /usr/lib/libpdal* /usr/lib/
COPY --from=build /usr/lib/pkgconfig/pdal.pc /usr/lib/pkgconfig/pdal.pc
COPY --from=build /usr/include/pdal /usr/include/pdal

# get laszip
COPY --from=build /usr/local/lib/liblaszip* /usr/local/lib/
COPY --from=build /usr/local/include/laszip /usr/local/include/laszip

RUN pdal --version
COPY simple.laz simple.laz
RUN pdal info simple.laz
