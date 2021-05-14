# R-builder-sif

This is a tool for automating builds of R and R packages into a container. Both Docker
format and Singularity format are created. The tool is built to be usable on Linux and
under Docker Desktop on Mac.

## How To

1. Create a text file called *packages-cran.txt* containing the names of the CRAN packages
you want to include, one name per line

2. Pick a name for your container. We'll use my-container-name for this example

3. ./make_container.sh my-container-name

A docker image tagged with your container's name will be written to your local image storage, 
and Singularity .sif format container will be written to the current directory.

## Conveniences

* Docker build cache will speed up subsequent builds

* The R package list is stored in / of the built container

## Known issues

* Some CRAN packages need more RAM to build successfully than Docker Desktop is configured with
by default. You may need to raise your Docker Desktop RAM and CPU limits.

* Multithreaded builds make the build log jumbled, making it hard to know which package's
compilation failed.

* Some CRAN packages will fail to compile unless you edit the Dockerfile to add in development
packages / Linux dependencies that they need.

* Docker build caching means base images will not be automatically refreshed

## ToDo

* Add Bioconductor support

* Add option to turn off Singularity container generation

* Add a way to change the R version without editing the Dockerfile

* Add a way to build with no cache
