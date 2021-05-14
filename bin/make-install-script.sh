#!/bin/sh

set -eu

t1=$(mktemp)
t2=$(mktemp)

printf 'R --slave -e @install.packages(c(' > "$t1"

grep -v '^#' packages-cran.txt | while read -r p ; do 
  printf '"%s", ' "$p" >> "$t1"
done

sed -e "s/, $//" "$t1" > "$t2"

printf '), repos="https://cloud.r-project.org/", Ncpus=8)@\n' >> "$t2"

grep -v '^#' packages-cran.txt | while read -r p ; do
  printf 'R --slave -e @library("%s")@\n' "$p" >> "$t2"
done

sed -e "s/@/\'/g" "$t2" > "$1/tmp/R-packages-CRAN.sh"

rm "$t1" "$t2"
