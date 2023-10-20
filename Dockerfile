FROM rockylinux:8

RUN yum -y upgrade

RUN yum -y install epel-release yum-utils which findutils libxml2-devel zlib-devel openssl-devel wget cmake git

RUN crb enable && yum-builddep -y R && yum -y install gdal-devel

ARG rmajor
ARG rversion
RUN cd /tmp && mkdir rbuild && cd rbuild && curl -O https://cloud.r-project.org/src/base/R-$rmajor/R-$rversion.tar.gz && \
  tar zxf R-$rversion.tar.gz && cd R-$rversion/ && ./configure --enable-memory-profiling --enable-R-shlib --with-cairo --with-libpng --with-jpeglib && make -j8 && make install && rm -rf /tmp/rbuild

COPY tmp/custom-pre-commands.sh /
RUN bash -e /custom-pre-commands.sh

COPY tmp/R-packages-cran.sh /
RUN bash -e /R-packages-cran.sh

COPY tmp/R-packages-bioc.sh /
RUN bash -e /R-packages-bioc.sh

COPY tmp/custom-commands.sh /
RUN bash -e /custom-commands.sh

# ENV RSTUDIO_SERVER_RPM=rstudio-server-rhel-2023.09.1-494-x86_64.rpm
# RUN wget https://download2.rstudio.org/server/rhel8/x86_64/${RSTUDIO_SERVER_RPM?} && yum install -y ./${RSTUDIO_SERVER_RPM?} && rm -v ./${RSTUDIO_SERVER_RPM?}

# Optional, recommended at https://docs.posit.co/resources/install-r-source/#optional-configure-r-to-use-a-different-blas-library
# RUN mv /usr/local/lib64/R/lib/libRblas.so /usr/local/lib64/R/lib/libRblas.so.keep && ln -vs /usr/lib64/libopenblasp.so /usr/local/lib64/R/lib/libRblas.so

RUN yum -y upgrade

RUN date > /build-date
