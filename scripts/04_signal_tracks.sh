#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
effective_genome_size=$4
threads=$5
fragment_length=$6

mkdir -p "$outdir"

tail -n +2 "$samples" | while IFS=$'\t' read -r sample _ _ _ _ _; do
    [[ -n "$sample" ]] || continue
    bam="$bamdir/${sample}.filtered.bam"
    [[ -f "$bam" ]] || { echo "BAM missing for $sample: $bam" >&2; exit 1; }
    bamCoverage --bam "$bam" \
        --outFileName "$outdir/${sample}.CPM.bw" \
        --outFileFormat bigwig \
        --normalizeUsing CPM \
        --effectiveGenomeSize "$effective_genome_size" \
        --binSize 25 \
        --extendReads "$fragment_length" \
        --numberOfProcessors "$threads"
done
