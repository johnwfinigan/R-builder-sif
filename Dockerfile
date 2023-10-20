FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'deb-src http://deb.debian.org/debian bookworm main\n\
deb-src http://deb.debian.org/debian-security/ bookworm-security main\n\
deb-src http://deb.debian.org/debian bookworm-updates main' >> /etc/apt/sources.list.d/deb-src.list

RUN apt -y update && apt -y dist-upgrade

RUN apt -y update && apt -y install curl locales locales-all bash tar gzip libxml2-dev zlib1g-dev libssl-dev wget

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apt -y update && apt -y build-dep r-base-core

ARG rmajor
ARG rversion
RUN cd /tmp && mkdir rbuild && cd rbuild && curl -O https://cloud.r-project.org/src/base/R-$rmajor/R-$rversion.tar.gz && \
  tar zxf R-$rversion.tar.gz && cd R-$rversion/ && ./configure --enable-R-shlib --with-cairo --with-libpng --with-jpeglib && make -j8 && make install && rm -rf /tmp/rbuild

COPY tmp/custom-pre-commands.sh /
RUN bash -e /custom-pre-commands.sh

COPY tmp/R-packages-cran.sh /
RUN bash -e /R-packages-cran.sh

COPY tmp/R-packages-bioc.sh /
RUN bash -e /R-packages-bioc.sh

COPY tmp/custom-commands.sh /
RUN bash -e /custom-commands.sh

RUN apt -y update && apt -y dist-upgrade

RUN date > /build-date
