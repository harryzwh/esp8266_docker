#FROM debian:buster-slim as compiler
FROM multiarch/debian-debootstrap:arm64-buster-slim as compiler

ARG BUILD_PATH=/build
RUN mkdir ${BUILD_PATH}
WORKDIR ${BUILD_PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
	git ca-certificates wget bzip2 patch g++ \
	gawk gperf grep gettext libncurses-dev python python-dev automake bison flex texinfo help2man libtool libtool-bin make \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/*

RUN git clone --depth 1 -b esp8266-1.22.x --single-branch https://github.com/espressif/crosstool-NG.git \
	&& cd crosstool-NG \
	&& git submodule update --init

WORKDIR ${BUILD_PATH}/crosstool-NG
ARG CT_EXPERIMENTAL=y
ARG CT_ALLOW_BUILD_AS_ROOT=y
ARG CT_ALLOW_BUILD_AS_ROOT_SURE=y

RUN ./bootstrap \
	&& ./configure --enable-local \
	&& make

RUN ./ct-ng xtensa-lx106-elf \
	&& ./ct-ng build
	
RUN rm ${BUILD_PATH}/crosstool-NG/builds/xtensa-lx106-elf/build.log.bz2

#FROM debian:buster-slim
FROM multiarch/debian-debootstrap:arm64-buster-slim

ARG TOOLS_PATH=/tools
RUN mkdir ${TOOLS_PATH}
WORKDIR ${TOOLS_PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
	gcc git wget make libncurses-dev flex bison gperf unzip libffi-dev libssl-dev \
	python python-dev python-serial python-pip python-wheel python-setuptools \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp

# Install xtensa toolchain
ARG TOOLCHAIN_PATH=${TOOLS_PATH}/toolchain
COPY --from=compiler /build/crosstool-NG/builds/xtensa-lx106-elf ${TOOLCHAIN_PATH}
ENV PATH="${TOOLCHAIN_PATH}/bin:${PATH}"

# Install RTOS SDK
ARG IDF_PATH=${TOOLS_PATH}/ESP8266_RTOS_SDK
RUN wget https://github.com/espressif/ESP8266_RTOS_SDK/releases/download/v3.3/ESP8266_RTOS_SDK-v3.3.zip -O ESP8266_RTOS_SDK.zip \
    && unzip ESP8266_RTOS_SDK.zip \
	&& rm ESP8266_RTOS_SDK.zip \
	&& rm -rf ${IDF_PATH}/.git \
	&& rm -rf ${IDF_PATH}/.github

RUN pip install --user -r ${IDF_PATH}/requirements.txt

#Install VScode
ARG TARGETARCH
RUN wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server-3.4.1-linux-${TARGETARCH}.tar.gz -O code-server.tar.gz \
	&& mkdir code-server \
	&& tar -zxvf code-server.tar.gz --strip-components 1 -C code-server \
	&& rm code-server.tar.gz

EXPOSE 8080

ENV PATH="${IDF_PATH}/tools:${TOOLS_PATH}/code-server/bin:${PATH}"
ENV IDF_PATH=${IDF_PATH}
ENV PWD=/build
ENV SHELL /bin/bash

# Change workdir
WORKDIR /build

#ENTRYPOINT ["code-server", "--auth", "none", "--bind-addr", "0.0.0.0:8080"]

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

