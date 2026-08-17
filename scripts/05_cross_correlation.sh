#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
phantompeak_script=${4:-}

mkdir -p "$outdir/logs"
if [[ -z "$phantompeak_script" ]]; then
    echo "PHANTOMPEAK_SCRIPT is empty; cross-correlation QC skipped."
    exit 0
fi
[[ -f "$phantompeak_script" ]] || { echo "phantompeak script not found: $phantompeak_script" >&2; exit 1; }

while IFS=$'\t' read -r sample condition replicate type r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    bam="$bamdir/${sample}.filtered.bam"
    [[ -f "$bam" ]] || { echo "BAM missing for $sample: $bam" >&2; exit 1; }
    Rscript "$phantompeak_script" \
        -c="$bam" \
        -savp \
        -out="$outdir/${sample}.qual" \
        > "$outdir/logs/${sample}.Rout" 2>&1
done < "$samples"

mv "$bamdir"/*.pdf "$outdir" 2>/dev/null || true
cat "$outdir"/*.qual > "$outdir/phantompeak_summary.tsv" 2>/dev/null || true
