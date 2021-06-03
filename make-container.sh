#!/bin/sh

set -e

if [ -z "$1" ] ; then
  echo "Error - you must provide a name for your container"
  echo "example: $0 my-container"
  exit 111
fi

container_name="$1"

set -u 

if [ ! -f packages-cran.txt ] ; then
  echo "Error - could not find packages-cran.txt"
  echo "add your desired CRAN package names to packages-cran.txt, one package name per line"
  exit 112
fi

bin/make-install-script.sh "$PWD"

docker build -t "$container_name" .

savefile=$(mktemp)
savefile_name=$(basename "$savefile")
savefile_dir=$(dirname "$savefile")

docker save "$container_name" > "$savefile"

d="$PWD"

cd singularity

rand=$(dd if=/dev/urandom count=1 bs=512 2>/dev/null | openssl sha1 )
singularity_tag="rbuilder-sif-singularity-${rand}" 
docker build -t "$singularity_tag" .

cd "$d"

docker run -v "$savefile_dir:/in" -v "$PWD:/out" -it "$singularity_tag" bash -c "singularity build /out/${container_name}.sif docker-archive://in/${savefile_name}"

set +e
rm "$savefile" 
rm tmp/R-packages-CRAN.sh
