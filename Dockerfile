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

#Install VScode
RUN wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server-3.4.1-linux-arm64.tar.gz \
	&& tar -zxvf code-server-3.4.1-linux-arm64.tar.gz \
	&& mv code-server-3.4.1-linux-arm64 code-server \
	&& rm code-server-3.4.1-linux-arm64.tar.gz

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
