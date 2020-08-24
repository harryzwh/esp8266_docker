FROM debian:buster-slim

ARG BUILD_PATH=/build
RUN mkdir ${BUILD_PATH}
WORKDIR ${BUILD_PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
	git ca-certificates wget \
	gawk gperf grep gettext libncurses-dev python python-dev automake bison flex texinfo help2man libtool libtool-bin make \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/*

RUN git clone --depth 1 -b esp8266-1.22.x --single-branch https://github.com/espressif/crosstool-NG.git \
	&& cd crosstool-NG \
	&& git submodule update --init

WORKDIR ${BUILD_PATH}/crosstool-NG

RUN ./bootstrap \
	&& ./configure --enable-local \
	&& make

RUN ./ct-ng xtensa-lx106-elf \
	&& ./crosstool-NG/ct-ng build
