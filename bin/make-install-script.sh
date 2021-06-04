#!/bin/sh

set -eu

biocversion=3.11

packagelist=$(mktemp)
t1=$(mktemp)
t2=$(mktemp)
t3=$(mktemp)
t="$t2"
:> "$1/tmp/R-packages.sh"

cat packages-cran.txt > "$packagelist"
# if we're going to be installing from Bioconductor,
# add BiocManager to install list
if [ -f packages-bioc.txt ] ; then
  echo BiocManager >> "$packagelist"
fi

printf 'R --slave -e @install.packages(c(' > "$t1"

grep -v '^#' "$packagelist" | while read -r p ; do 
  printf '"%s", ' "$p" >> "$t1"
done

sed -e "s/, $//" "$t1" > "$t2"

printf '), repos="https://cloud.r-project.org/", Ncpus=8)@\n' >> "$t2"


if [ -f packages-bioc.txt ] ; then
  printf 'R --slave -e @BiocManager::install(version = "%s", ask = FALSE, force = TRUE)@\n' "$biocversion" >> "$t2"
  printf 'R --slave -e @BiocManager::install(c(' >> "$t2"
  grep -v '^#' packages-bioc.txt | while read -r p ; do
    printf '"%s", ' "$p" >> "$t2"
  done

  sed -e "s/, $//" "$t2" > "$t3"
  printf '), Ncpus=8)@\n' >> "$t3"

  cat packages-bioc.txt >> "$packagelist"
  t="$t3"
fi
    


grep -v '^#' "$packagelist" | while read -r p ; do
  printf 'R --slave -e @library("%s")@\n' "$p" >> "$t"
done

sed -e "s/@/\'/g" "$t" > "$1/tmp/R-packages.sh"

rm "$t1" "$t2" "$t3" "$packagelist"
