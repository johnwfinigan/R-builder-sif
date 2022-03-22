#!/bin/sh

set -eu
getname() {
  rand=$(dd if=/dev/urandom count=1 bs=512 2>/dev/null | openssl sha1 | awk '{print $NF}')
  randname="r-builder-sif-test-temporary-${rand}"
}

echo "$(date) starting tests" > test.log

# basic case, just cran, just defaults
echo data.table > packages-cran.txt
getname
#./make-container.sh -n "$randname"
./make-container.sh "$randname"
echo "$(date) Basic case pass" | tee -a test.log

# bioconductor with defaults
:> packages-cran.txt
echo IRanges > packages-bioc.txt
getname
./make-container.sh "$randname"
echo "$(date) Bioconductor case pass" | tee -a test.log

# test use of post script
:> packages-cran.txt
echo IRanges > packages-bioc.txt
echo true > post.txt
getname
./make-container.sh -p post.txt "$randname"
echo "$(date) post script case pass" | tee -a test.log

# custom R version, guess bioconductor version, test sif generation
echo IRanges > packages-bioc.txt
echo data.table > packages-cran.txt
getname
./make-container.sh -r 3.6.3 -s "$randname"
if [ ! -f "${randname}.sif" ] ; then
  echo "sif file was not generated, exiting" >&2
  exit 150
fi
echo "$(date) custom R case pass, sif pass" | tee -a test.log

# test convert without tag
docker pull ubuntu:latest
getname
./make-container.sh -c ubuntu
if [ ! -f ubuntu.sif ] ; then
  echo "convert only test failed" >&2
  exit 151
fi
echo "$(date) untagged convert pass" | tee -a test.log

# test convert with tag
# centos:7 will have already been pulled by sif generation step
getname
./make-container.sh -c centos:7
if [ ! -f centos_7.sif ] ; then
  echo "convert only test failed" >&2
  exit 151
fi
echo "$(date) tagged convert pass" | tee -a test.log

echo "$(date) tests completed, elapsed $SECONDS seconds" | tee -a test.log




