#!/bin/sh

set -eu

t1=$(mktemp)
t2=$(mktemp)
t3=$(mktemp)
t4=$(mktemp)
outfile_cran="$1/tmp/R-packages-cran.sh"
outfile_bioc="$1/tmp/R-packages-bioc.sh"
custom="$1/tmp/custom-commands.sh"
:> "$outfile_cran"
:> "$outfile_bioc"
:> "$custom"
bioc_version="$2"
post_script="$3"
threads=8

printf 'set -e\n' > "$t1"
printf 'R --slave -e @install.packages(c(' >> "$t1"
grep -v '^#' packages-cran.txt | while read -r p ; do 
  printf '"%s", ' "$p" >> "$t1"
done
sed -e "s/, $//" "$t1" > "$t2"
printf '), repos="https://cloud.r-project.org/", Ncpus=%d)@\n' "$threads" >> "$t2"

grep -v '^#' packages-cran.txt | while read -r p ; do
  printf 'R --slave -e @library("%s")@\n' "$p" >> "$t2"
done
sed -e "s/@/\'/g" "$t2" > "$outfile_cran"

if [ -f packages-bioc.txt ] ; then
  printf 'R --slave -e @install.packages("BiocManager", repos="https://cloud.r-project.org/")@\n' > "$t3"
  printf 'R --slave -e @BiocManager::install(version = "%s", ask = FALSE, force = TRUE)@\n' "$bioc_version" >> "$t3"
  printf 'R --slave -e @BiocManager::install(c(' >> "$t3"
  grep -v '^#' packages-bioc.txt | while read -r p ; do
    printf '"%s", ' "$p" >> "$t3"
  done
  sed -e "s/, $//" "$t3" > "$t4"
  printf '), Ncpus=%d)@\n' "$threads" >> "$t4"

  printf 'R --slave -e @library("BiocManager")@\n' >> "$t4"
  grep -v '^#' packages-bioc.txt | while read -r p ; do
    printf 'R --slave -e @library("%s")@\n' "$p" >> "$t4"
  done
  sed -e "s/@/\'/g" "$t4" > "$outfile_bioc"

fi

if [ "$post_script" != "NONE" ] ; then
  if [ ! -f "$post_script" ] ; then
    echo "Custom install commands script file specified, but file cannot be found, exiting" 1>&2
    exit 117
  fi
  cat "$post_script" > "$custom"
fi

rm "$t1" "$t2" "$t3" "$t4"
