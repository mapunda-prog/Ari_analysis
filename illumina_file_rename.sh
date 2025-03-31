#!/bin/bash

set -uex

# Loop through all fastq.gz files in current directory
for file in *.fastq.gz; do
    if [[ $file =~ ([^_]+)_S[0-9]+_L[0-9]+_(R[12])_001\.fastq\.gz ]]; then
        # Extract the sample name and read number
        sample="${BASH_REMATCH[1]}"
        read_num="${BASH_REMATCH[2]}"
        
        # Remove any hyphens from sample name
        sample_clean="${sample//-/}"
        
        # Create new filename
        new_name="${sample_clean}_${read_num}.fastq.gz"
        
        # Rename the file
        echo "Renaming $file to $new_name"
        mv "$file" "$new_name"
    else
        echo "Warning: $file doesn't match expected pattern"
    fi
done