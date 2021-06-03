FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted\n\
deb-src http://archive.ubuntu.com/ubuntu/ focal-updates main restricted\n\
deb-src http://archive.ubuntu.com/ubuntu/ focal universe\n\
deb-src http://archive.ubuntu.com/ubuntu/ focal-updates universe\n' >> /etc/apt/sources.list


RUN apt -y update && apt -y dist-upgrade

RUN apt -y install curl locales locales-all bash tar gzip

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apt -y build-dep r-base-core

# Change to your desired R version

ENV version 4.0.5

RUN cd /tmp && mkdir rbuild && cd rbuild && curl -O https://cran.r-project.org/src/base/R-4/R-$version.tar.gz && \
  tar zxf R-$version.tar.gz && cd R-$version/ && ./configure && make -j8 && make install && rm -rf /tmp/rbuild

RUN apt-get -y install libxml2-dev zlib1g-dev libssl-dev

COPY tmp/R-packages.sh /

RUN chmod 700 /R-packages.sh && /R-packages.sh
