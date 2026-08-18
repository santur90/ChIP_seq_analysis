#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
bigwigdir=$3
outdir=$4
regions_bed=${5:-}
effective_genome_size=$6
threads=$7
fragment_length=$8

mkdir -p "$outdir/bamcompare" "$outdir/figures"
# shellcheck disable=SC2094  # the sample sheet is only ever read, never written, in this loop
while IFS=$'\t' read -r sample condition replicate type _ _; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    [[ "$type" == "chip" ]] || continue
    input_sample=$(awk -F '\t' -v c="$condition" -v r="$replicate" 'NR > 1 && $2 == c && $3 == r && $4 == "input" {print $1; exit}' "$samples")
    [[ -n "$input_sample" ]] || continue
    chip_bam="$bamdir/${sample}.filtered.bam"
    input_bam="$bamdir/${input_sample}.filtered.bam"
    [[ -f "$chip_bam" && -f "$input_bam" ]] || continue
    bamCompare \
        -b1 "$chip_bam" -b2 "$input_bam" \
        -o "$outdir/bamcompare/${sample}_vs_${input_sample}.log2ratio.bw" \
        --operation log2 \
        --normalizeUsing CPM \
        --effectiveGenomeSize "$effective_genome_size" \
        --extendReads "$fragment_length" \
        --binSize 25 \
        -p "$threads"
done < "$samples"

if [[ -z "$regions_bed" ]]; then
    echo "REGIONS_BED is empty; profile and heatmap generation skipped."
    exit 0
fi
[[ -f "$regions_bed" ]] || { echo "Regions BED not found: $regions_bed" >&2; exit 1; }
shopt -s nullglob
signal_files=("$bigwigdir"/*.CPM.bw)
[[ "${#signal_files[@]}" -gt 0 ]] || { echo "No CPM bigWig files found in $bigwigdir" >&2; exit 1; }
computeMatrix reference-point \
    --referencePoint TSS \
    -b 1000 -a 1000 \
    -R "$regions_bed" \
    -S "${signal_files[@]}" \
    --skipZeros \
    -o "$outdir/TSS_matrix.gz" \
    --outFileSortedRegions "$outdir/TSS_regions.sorted.bed" \
    -p "$threads"
plotProfile \
    -m "$outdir/TSS_matrix.gz" \
    -out "$outdir/figures/TSS_profile.png" \
    --perGroup \
    --refPointLabel TSS \
    --plotTitle "ChIP-seq signal around TSS"
plotHeatmap \
    -m "$outdir/TSS_matrix.gz" \
    -out "$outdir/figures/TSS_heatmap.png" \
    --colorMap RdBu_r \
    --whatToShow "heatmap and colorbar"
