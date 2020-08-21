FROM debian:buster-slim

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
ARG TOOLCHAIN_TARBALL_URL=https://github.com/harryzwh/xtensa-lx106-elf-RPi/releases/download/v1.22.0-97/xtensa-lx106-elf-arm64-1.22.0-97-gca13a260-5.2.0.tar.gz
ARG TOOLCHAIN_PATH=${TOOLS_PATH}/toolchain
RUN wget ${TOOLCHAIN_TARBALL_URL} \
	&& export TOOLCHAIN_TARBALL_FILENAME=$(basename "${TOOLCHAIN_TARBALL_URL}") \
	&& tar -xvf ${TOOLCHAIN_TARBALL_FILENAME}  \
	&& mv `tar -tf ${TOOLCHAIN_TARBALL_FILENAME} | head -1` ${TOOLCHAIN_PATH} \
	&& rm ${TOOLCHAIN_TARBALL_FILENAME}

ENV PATH="${TOOLCHAIN_PATH}/bin:${PATH}"

# Install RTOS SDK
ARG IDF_PATH=${TOOLS_PATH}/ESP8266_RTOS_SDK
RUN wget https://github.com/espressif/ESP8266_RTOS_SDK/releases/download/v3.3/ESP8266_RTOS_SDK-v3.3.zip -O ESP8266_RTOS_SDK.zip \
    && unzip ESP8266_RTOS_SDK.zip \
	&& rm ESP8266_RTOS_SDK.zip \
	&& rm -rf ${IDF_PATH}/.git \
	&& rm -rf ${IDF_PATH}/.github

RUN pip install --user -r ${IDF_PATH}/requirements.txt

ENV PATH="${IDF_PATH}/tools:${PATH}"
ENV IDF_PATH=${IDF_PATH}
ENV PWD=/build

# Change workdir
WORKDIR /build