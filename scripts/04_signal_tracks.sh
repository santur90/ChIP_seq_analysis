#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
effective_genome_size=$4
threads=$5

mkdir -p "$outdir"

tail -n +2 "$samples" | while IFS=$'\t' read -r sample condition replicate type r1 r2; do
    [[ -n "$sample" ]] || continue
    bam="$bamdir/${sample}.sorted.bam"
    [[ -f "$bam" ]] || { echo "BAM missing for $sample: $bam" >&2; exit 1; }
    bamCoverage --bam "$bam" \
        --outFileName "$outdir/${sample}.CPM.bw" \
        --outFileFormat bigwig \
        --normalizeUsing CPM \
        --effectiveGenomeSize "$effective_genome_size" \
        --binSize 25 \
        --numberOfProcessors "$threads"
done
