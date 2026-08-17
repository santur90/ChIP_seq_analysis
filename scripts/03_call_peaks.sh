#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
genome_size=$4
threads=$5

mkdir -p "$outdir"

tail -n +2 "$samples" | while IFS=$'\t' read -r sample condition replicate type r1 r2; do
    [[ -n "$sample" ]] || continue
    [[ "$type" == "chip" ]] || continue

    input_sample=$(awk -F '\t' -v c="$condition" -v r="$replicate" 'NR > 1 && $2 == c && $3 == r && $4 == "input" {print $1; exit}' "$samples")
    [[ -n "$input_sample" ]] || { echo "No matching Input for $sample" >&2; exit 1; }
    chip_bam="$bamdir/${sample}.sorted.bam"
    input_bam="$bamdir/${input_sample}.sorted.bam"
    [[ -f "$chip_bam" && -f "$input_bam" ]] || { echo "BAM missing for $sample or $input_sample" >&2; exit 1; }

    macs3 callpeak \
        -t "$chip_bam" -c "$input_bam" \
        -f BAMPE -g "$genome_size" \
        -n "$sample" --outdir "$outdir" \
        --keep-dup all --qvalue 0.05 --nomodel --extsize 150

done
