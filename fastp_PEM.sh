#!/bin/bash

set -uex

# Define variables
input_dir="/tank/lmapunda/ARI/work_fastqs"
output_dir="/tank/lmapunda/ARI/fastp_trim"
mkdir -p $output_dir
# iterate over forward read files
for file1 in "${input_dir}"/*_R1.fastq.gz; do

  # extract filename prefix
  filename=$(basename "${file1}" _R1.fastq.gz)

  # construct reverse read file name
  file2="${input_dir}/${filename}_R2.fastq.gz"

  # run fastp
  fastp --in1 "${file1}" \
        --in2 "${file2}" \
        --out1 "${output_dir}/${filename}_R1.fastq.gz" \
        --out2 "${output_dir}/${filename}_R2.fastq.gz" \
        --trim_poly_g \
          --correction \
          --cut_tail \
          --length_required 50 \
          --qualified_quality_phred 30 \
          -f 15 \
          -F 15 \
          --thread 100 \
          --html "${output_dir}/${filename}_report.html" \
          --json "${output_dir}/${filename}_report.json"

done
