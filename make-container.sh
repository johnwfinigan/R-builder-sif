#!/bin/sh

set -e

makesif=YES
r_version=4.1.0
bioc_version=NONE
post_script=NONE

while getopts :r:sb:p: opt; do
  case "$opt" in
    r )
      r_version="$OPTARG"
      ;;
    s )
      makesif=NO
      ;;
    b )
      bioc_version="$OPTARG"
      ;;
    p )
      post_script="$OPTARG"
      ;;
    \? )
      echo "invalid option, exiting" 2>&1
      exit 113
      ;;
    : )
      echo "-$OPTARG needs an argument, exiting" 1>&2
      exit 114
      ;;
  esac
done

shift $((OPTIND - 1))
if [ -z "$1" ] ; then
  echo "Error - you must provide a name for your container"
  echo "example: $0 my-container"
  exit 111
fi
container_name="$1"

r_major=$(echo "$r_version" | cut -d. -f1)
r_major_minor=$(echo "$r_version" | cut -d. -f1,2)
if [ -f packages-bioc.txt ] ; then
  if [ "$bioc_version" = "NONE" ] ; then
    case "$r_major_minor" in
      3.6)
        bioc_version=3.9
        ;;
      4.0)
        bioc_version=3.11
        ;;
      4.1)
        bioc_version=3.13
        ;;
      *)
        echo "R major minor $r_major_minor" 1>&2
        echo "cannot guess bioconductor version, exiting" 1>&2
        exit 115
        ;;
    esac
  fi
fi

set -u 

if [ ! -f packages-cran.txt ] ; then
  echo "Error - could not find packages-cran.txt"
  echo "add your desired CRAN package names to packages-cran.txt, one package name per line"
  echo "bioconductor packages must be added to packages-bioc.txt instead"
  exit 112
fi

bin/make-install-script.sh "$PWD" "$bioc_version" "$post_script"

docker build --build-arg rversion="$r_version" --build-arg rmajor="$r_major" -t "$container_name" .

if [ "$makesif" = "YES" ] ; then
  
  savefile=$(mktemp)
  savefile_name=$(basename "$savefile")
  savefile_dir=$(dirname "$savefile")
  
  docker save "$container_name" > "$savefile"
  
  d="$PWD"
  
  cd singularity
  
  rand=$(dd if=/dev/urandom count=1 bs=512 2>/dev/null | openssl sha1 | awk '{print $NF}')
  singularity_tag="rbuilder-sif-singularity-${rand}" 
  docker build -t "$singularity_tag" .
  
  cd "$d"
  
  docker run -v "$savefile_dir:/in" -v "$PWD:/out" -it "$singularity_tag" bash -c "singularity build /out/${container_name}.sif docker-archive://in/${savefile_name}"
  
  set +e
  rm "$savefile" 
fi

printf "R version: %s\nR major: %s\nR major minor: %s\nBioconductor version: %s\nMake .sif file: %s\nCustom install commands from: %s\n" "$r_version" "$r_major" "$r_major_minor" "$bioc_version" "$makesif" "$post_script" 1>&2
