#!/bin/bash

set -uex

for file in *_R1_*.fastq.gz
do
  base=$(echo $file | cut -d'_' -f1)
  mv "$file" "${base}_R1.fastq.gz"
done

for file in *_R2_*.fastq.gz
do
  base=$(echo $file | cut -d'_' -f1)
  mv "$file" "${base}_R2.fastq.gz"
done
