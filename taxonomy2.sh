#!/bin/bash

set -uex

# Usage information
usage() {
    echo -e "\033[1;34m[INFO::] Usage: $0 -i <input_reads_folder> -p <project_folder> -d <kraken2_db> [-t <threads>]\033[0m"
    echo ""
    echo "Options:"
    echo "  -i, --input          Path to the folder containing renamed FASTQ files (required)."
    echo "  -p, --project        Path to the project folder where all results will be stored (required)."
    echo "  -d, --kraken2_db     Path to the Kraken2 database (required)."
    echo "  -t, --threads        Number of threads to use (optional, default: 10)."
    echo "  -h, --help           Display this help message."
    exit 1
}

# Default values
THREADS=300

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_DIR="$(realpath "$2")"; shift 2;;
        -p|--project) PROJECT_DIR="$(realpath "$2")"; shift 2;;
        -d|--kraken2_db) KRAKEN_DB="$(realpath "$2")"; shift 2;;
        -t|--threads) THREADS="$2"; shift 2;;
        -h|--help) usage;;
        *) echo "Unknown option: $1"; usage;;
    esac
done

# Check if required arguments are provided
if [[ -z "$INPUT_DIR" || -z "$PROJECT_DIR" || -z "$KRAKEN_DB" ]]; then
    echo -e "\033[1;31m[ERROR::] Missing required arguments.\033[0m"
    usage
fi

# Create main output directories
KRAKEN_OUT="$PROJECT_DIR/Kraken2"
BRACKEN_OUT="$PROJECT_DIR/Bracken"
DEHOST_OUT="$PROJECT_DIR/Dehosted"
ASSEMBLY_OUT="$PROJECT_DIR/Assembly"
CONTIG_PROF_OUT="$PROJECT_DIR/ContigProfiling"

mkdir -p "$KRAKEN_OUT" "$BRACKEN_OUT" "$DEHOST_OUT" "$ASSEMBLY_OUT" "$CONTIG_PROF_OUT"

# Loop through all _R1.fastq files and process each sample
for fwd_file in "$INPUT_DIR"/*_R1.fastq*; do
    sample=$(basename "$fwd_file" | sed -E 's/_R1\.fastq(\.gz)?//')
    rev_file="$INPUT_DIR/${sample}_R2.fastq"
    rev_file_gz="$INPUT_DIR/${sample}_R2.fastq.gz"
    
    if [[ ! -f "$rev_file" && ! -f "$rev_file_gz" ]]; then
        echo -e "\033[1;31m[ERROR::] Paired-end file not found for $sample: $rev_file or $rev_file_gz\033[0m"
        continue
    fi
    
    rev_file_exists="$rev_file"
    if [[ -f "$rev_file_gz" ]]; then
        rev_file_exists="$rev_file_gz"
    fi
    
    echo -e "\033[1;34m[INFO::] Processing sample $sample...\033[0m"
    
    # Step 1: Run Kraken2 on raw reads
    echo -e "\033[1;33m[INFO::] Running Kraken2 on raw reads for $sample...\033[0m"
    kraken2 --db "$KRAKEN_DB" --threads "$THREADS" \
            --paired "$fwd_file" "$rev_file_exists" \
            --unclassified-out "$KRAKEN_OUT/${sample}_unclassified#.fastq" \
            --classified-out "$KRAKEN_OUT/${sample}_classified#.fastq" \
            --output "$KRAKEN_OUT/${sample}_kraken_out.txt" \
            --report "$KRAKEN_OUT/${sample}_kraken_report.txt" \
            --use-names --memory-mapping
    
    # Step 2: Run Bracken on Kraken2 results
    echo -e "\033[1;33m[INFO::] Running Bracken on Kraken2 results for $sample...\033[0m"
    bracken -d "$KRAKEN_DB" -i "$KRAKEN_OUT/${sample}_kraken_report.txt" \
            -o "$BRACKEN_OUT/${sample}_bracken_output.txt" \
            -w "$BRACKEN_OUT/${sample}_bracken_report.txt" -l S -t "$THREADS"
    
    echo -e "\033[1;32m[INFO::] Finished processing $sample.\033[0m"
done
