# R-builder-sif

This is a tool for automating builds of R and R packages into a container. Both Docker
format and Singularity format can be created. The tool is built to be usable on Linux and
under Docker Desktop on Mac. There is now experimental support for Rancher Desktop on Mac.

On Linux, your build machine must have Docker installed. 
You do not need singularity installed on your build machine to use this tool to generate .sif files.

## News - read this if you used previous versions

* You must pass ```-s``` to enable Singularity .sif file generation. sif generation is now off by default.

* Default R version used, if you do not specify another, is now 4.2.1

* Custom commands and bioconductor packages are now broken into separate container layers, enhancing build caching.

* Experimental support for Rancher Desktop, tested on Mac! To use Rancher Desktop and nerdctl,

```
export R_BUILDER_SIF_CONTAINER_CMD=nerdctl
```

before running make-container.sh

* convert-only mode: convert any pre-existing Docker format container to Singularity format, independent of R build functionality

## How To - Build R container

* Create a text file called *packages-cran.txt* containing the names of the CRAN packages
you want to include, one name per line

* Optionally create a file called *packages-bioc.txt* with names of Bioconductor packages, as above

* Pick a name for your container. We'll use *my-container-name* for this example:

* ```./make-container.sh my-container-name```

A docker image tagged with your container's name will be written to your local image storage.
If you passed the ```-s``` option (described below), a Singularity .sif format container will be written to the current directory.

## How To - Convert an Existing Container from Docker to Singularity format

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

### Turn on singularity .sif generation: -s 

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

* Some CRAN packages will fail to compile due to missing dependencies. This can usually be addressed by use of a post install script and the ```-p``` option.

* Docker build caching means base images will not be automatically refreshed, but you can pass ```-n``` to ensure that they are.

