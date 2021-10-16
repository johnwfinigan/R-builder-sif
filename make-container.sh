#!/bin/sh

set -e

makesif=NO
r_version=4.1.1
bioc_version=NONE
post_script=NONE
container_builder_cache=" "
container_cmd=docker

# allow use of alternate container tools
# but, do not directly use unsanitized input
if [ -n "$R_BUILDER_SIF_CONTAINER_CMD" ] ; then
  if [ "$R_BUILDER_SIF_CONTAINER_CMD" = nerdctl ] ; then
    container_cmd=nerdctl  # for Rancher Desktop
  elif [ "$R_BUILDER_SIF_CONTAINER_CMD" != docker ] ; then
    echo "R_BUILDER_SIF_CONTAINER_CMD set to unrecognized value, exiting." >&2
    echo "try running:    unset R_BUILDER_SIF_CONTAINER_CMD" >&2
    exit 120 
  fi
fi

for f in R-packages.sh custom-commands.sh ; do
  if [ -f "tmp/${f}" ] ; then
    rm "tmp/${f}" || exit 119
  fi
done

while getopts :r:snb:p: opt; do
  case "$opt" in
    r )
      r_version="$OPTARG"
      ;;
    s )
      makesif=YES
      ;;
    b )
      bioc_version="$OPTARG"
      ;;
    p )
      post_script="$OPTARG"
      ;;
    n )
      container_builder_cache="--no-cache"
      ;;
    \? )
      echo "invalid option, exiting" >&2
      exit 113
      ;;
    : )
      printf "\55%s needs an argument, exiting\n" "$OPTARG" >&2
      exit 114
      ;;
  esac
done

shift $((OPTIND - 1))
if [ -z "$1" ] ; then
  echo "Error - you must provide a name for your container" >&2
  echo "example: $0 my-container" >&2
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
        echo "R major minor $r_major_minor" >&2
        echo "cannot guess bioconductor version, exiting" >&2
        echo "try specifying bioconductor version with -b" >&2
        exit 115
        ;;
    esac
  fi
fi

set -u 

if [ ! -f packages-cran.txt ] ; then
  echo "Error - could not find packages-cran.txt" >&2
  echo "add your desired CRAN package names to packages-cran.txt, one package name per line" >&2
  echo "bioconductor packages must be added to packages-bioc.txt instead" >&2
  exit 112
fi

bin/make-install-script.sh "$PWD" "$bioc_version" "$post_script"

"$container_cmd" build $container_builder_cache --build-arg rversion="$r_version" --build-arg rmajor="$r_major" -t "$container_name" .

if [ "$makesif" = "YES" ] ; then
  
  if [ "$(uname)" = "Darwin" ] ; then
    # mktemp on macos ignores TMPDIR and hardcodes the parent
    # directory of mktemp files. because nerdctl cannot read files at
    # this hardcoded location, we lose the ability to use mktemp.

    rand=$(dd if=/dev/urandom count=1 bs=512 2>/dev/null | openssl sha1 | awk '{print $NF}')
    savefile="savefile.${rand}"
    :> "$savefile"
  else
    savefile=$(mktemp -p . -t savefile.XXXXXXXXXX)
  fi

  savefile_name=$(basename "$savefile")
  
  "$container_cmd" save "$container_name" > "$savefile"
  
  d="$PWD"
  
  cd singularity
  
  rand=$(dd if=/dev/urandom count=1 bs=512 2>/dev/null | openssl sha1 | awk '{print $NF}')
  singularity_tag="rbuilder-sif-singularity-${rand}" 
  "$container_cmd" build $container_builder_cache -t "$singularity_tag" .
  
  cd "$d"
  
  "$container_cmd" run -v "$PWD:/out" -it "$singularity_tag" bash -c "singularity build /out/${container_name}.sif docker-archive:///out/${savefile_name}"
  
  set +e
  rm -v "$savefile" 
fi

printf "R version: %s\nR major: %s\nR major minor: %s\nBioconductor version: %s\nMake .sif file: %s\nCustom install commands from: %s\n" "$r_version" "$r_major" "$r_major_minor" "$bioc_version" "$makesif" "$post_script"
