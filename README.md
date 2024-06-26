# R-builder-sif

This is a tool for automating builds of R and R packages into a container. Both Docker
format and Apptainer (Singularity) format can be created. The tool is built to be usable on Linux and
under Docker Desktop on Mac, but is designed to be container runtime agnostic, and any roughly Docker-compatible runtime should work.

On Linux, your build machine must have Docker or Podman installed. 
You do not need Apptainer or Singularity installed on your build machine to use this tool to generate .sif files.

## News - read this if you used previous versions

* Default Linux base image updated to Ubuntu 22.04, since 20.04 has less than a year left of standard support

* Experimental support for using a Rocky Linux 8 base image: ```git fetch origin unstable-rocky8 && git checkout unstable-rocky8```

* Default R updated to 4.4.0

* Podman support now well tested and is the recommended container runtime on Linux: ```export R_BUILDER_SIF_CONTAINER_CMD=podman```

* Bug fix: scripts are now all run with bash -e to ensure that they fail on first error

* Bug fix: auto-guessed Bioconductor version now defaults to the latest release for the corresponding R version. This was done to address known compilation failures. It remains possible to specify your Bioconductor version explicitly.

* Added ability to specify a pre script using ```-e```. This is like the post script, but runs before CRAN and bioconductor package installs run. Useful for installing special build dependencies. 

* convert-only mode: convert any pre-existing Docker format container to Apptainer format, independent of R build functionality

* Singularity container export now done using Apptainer

* You must pass ```-s``` to enable Apptainer .sif file generation. sif generation is now off by default.

* Default R version used, if you do not specify another, is now 4.2.2

* Custom commands and bioconductor packages are now broken into separate container layers, enhancing build caching.

* Experimental support for Rancher Desktop, tested on Mac! To use Rancher Desktop and nerdctl, ```export R_BUILDER_SIF_CONTAINER_CMD=nerdctl``` before running make-container.sh

## How To - Build R container

* Create a text file called *packages-cran.txt* containing the names of the CRAN packages
you want to include, one name per line

* Optionally create a file called *packages-bioc.txt* with names of Bioconductor packages, as above

* Pick a name for your container. We'll use *my-container-name* for this example:

* ```./make-container.sh my-container-name```

A docker image tagged with your container's name will be written to your local image storage.
If you passed the ```-s``` option (described below), a Apptainer .sif format container will be written to the current directory.

## How To - Convert an Existing Container from Docker to Apptainer format

The container you want to convert must already be in your local registry. 
You must either build it from a Dockerfile or pull it from a remote registry, before converting.
Once it's in your local registry, run:

```
./make-container.sh -c container_name:tag
```

If you omit the tag, "latest" is implicitly used.

## Command Line Options

### Manually specify R version:  -r 

```./make-container.sh -r 4.0.4 my-container-name```

### Manually specify Bioconductor version: -b

```make-container.sh -r 4.1.0 -b 3.13 my-container-name```

```make-container.sh``` will try to guess the right Bioconductor version for you without you needing to specificy it manually, though.

### Turn on Apptainer .sif generation: -s 

```./make-container.sh -s my-container-name```

If you do not pass ```-s```, only a Docker image is built.

### Run arbitrary UNIX commands at the end of the build: -p

```./make-container.sh -p post.txt my-container-name```

post.txt can contain any UNIX commands you need run at the end of the container build. The contents of post.txt will be run after the CRAN and Bioconductor builds are run. This is useful for installing packages which require dependencies not in the standard build. Sample post.txt contents: 

```
apt update && apt -y install git libgdal-dev libnlopt-dev
R --no-echo -e 'library("devtools"); devtools::install_github("PheWAS/PheWAS")'
R --no-echo -e 'install.packages("rgdal", repos="https://cloud.r-project.org/")'
R --no-echo -e 'library("rgdal")'
R --no-echo -e 'library("PheWAS")'
```

### Run arbitrary UNIX commands at the beginning of the build: -e

Same as ```-p``` but runs before R library builds. Useful for installing special dependencies.

### Turn off docker build cache: -n

```./make-container.sh -n my-container-name```

By default, Ubuntu packages from your base container will be updated at the end of the build, even if you do not pass ```-n```

### Convert-only mode: -c 

See How-To above.

## Conveniences

* Docker build cache will speed up subsequent builds

* The generated R package install script and build date is stored in / of the built container

## Known issues


* If using Bioconductor, packages-cran.txt must exist but may be empty

* Some CRAN packages need more RAM to build successfully than Docker Desktop is configured with
by default. You may need to raise your Docker Desktop RAM and CPU limits.

* Multithreaded builds make the build log jumbled, making it hard to know which package's
compilation failed.

* Some CRAN packages will fail to compile due to missing dependencies. This can usually be addressed by use of a pre install script and the ```-e``` option.

* Docker build caching means base images will not be automatically refreshed, but you can pass ```-n``` to ensure that they are. 

