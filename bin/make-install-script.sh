#!/bin/sh

set -eu

packagelist=$(mktemp)
t1=$(mktemp)
t2=$(mktemp)
t3=$(mktemp)
t="$t2"
outfile="$1/tmp/R-packages.sh"
:> "$outfile"
bioc_version="$2"
post_script="$3"
threads=8

cat packages-cran.txt > "$packagelist"
# if we're going to be installing from Bioconductor,
# add BiocManager to install list
if [ -f packages-bioc.txt ] ; then
  echo BiocManager >> "$packagelist"
fi

printf 'set -e\n' > "$t1"
printf 'R --slave -e @install.packages(c(' >> "$t1"

grep -v '^#' "$packagelist" | while read -r p ; do 
  printf '"%s", ' "$p" >> "$t1"
done

sed -e "s/, $//" "$t1" > "$t2"

printf '), repos="https://cloud.r-project.org/", Ncpus=%d)@\n' "$threads" >> "$t2"


if [ -f packages-bioc.txt ] ; then
  printf 'R --slave -e @BiocManager::install(version = "%s", ask = FALSE, force = TRUE)@\n' "$bioc_version" >> "$t2"
  printf 'R --slave -e @BiocManager::install(c(' >> "$t2"
  grep -v '^#' packages-bioc.txt | while read -r p ; do
    printf '"%s", ' "$p" >> "$t2"
  done

  sed -e "s/, $//" "$t2" > "$t3"
  printf '), Ncpus=%d)@\n' "$threads" >> "$t3"

  cat packages-bioc.txt >> "$packagelist"
  t="$t3"
fi


grep -v '^#' "$packagelist" | while read -r p ; do
  printf 'R --slave -e @library("%s")@\n' "$p" >> "$t"
done

sed -e "s/@/\'/g" "$t" > "$outfile"

if [ "$post_script" != "NONE" ] ; then
  if [ ! -f "$post_script" ] ; then
    echo "Custom install commands script file specified, but file cannot be found, exiting" 1>&2
    exit 117
  fi
  cat "$post_script" >> "$outfile"
fi

rm "$t1" "$t2" "$t3" "$packagelist"
