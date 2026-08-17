#!/usr/bin/env bash
set -euo pipefail

samples=$1
peakdir=$2
outdir=$3
idr_threshold=$4

mkdir -p "$outdir"
conditions=$(awk -F '\t' 'NR > 1 && $4 == "chip" {print $2}' "$samples" | sort -u)
while IFS= read -r condition; do
    [[ -n "$condition" ]] || continue
    peak_files=()
    chip_samples=$(awk -F '\t' -v c="$condition" 'NR > 1 && $2 == c && $4 == "chip" {print $1}' "$samples")
    while IFS= read -r sample; do
        [[ -n "$sample" ]] || continue
        peak_file="$peakdir/${sample}_peaks.narrowPeak"
        [[ -f "$peak_file" ]] && peak_files+=("$peak_file")
    done <<< "$chip_samples"

    if [[ "${#peak_files[@]}" -lt 2 ]]; then
        echo "Fewer than two peak sets for condition $condition; replicate comparison skipped."
        continue
    fi

    first_peak="${peak_files[0]}"
    second_peak="${peak_files[1]}"
    bedtools intersect -a "$first_peak" -b "$second_peak" -wa -wb > "$outdir/${condition}.overlap.narrowPeak"

    if command -v idr >/dev/null 2>&1; then
        sort -k8,8nr "$first_peak" > "$outdir/${condition}.rep1.sorted.narrowPeak"
        sort -k8,8nr "$second_peak" > "$outdir/${condition}.rep2.sorted.narrowPeak"
        idr \
            --samples "$outdir/${condition}.rep1.sorted.narrowPeak" "$outdir/${condition}.rep2.sorted.narrowPeak" \
            --input-file-type narrowPeak \
            --rank p.value \
            --idr-threshold "$idr_threshold" \
            --output-file "$outdir/${condition}.idr" \
            --plot \
            --log-output-file "$outdir/${condition}.idr.log"
    else
        echo "idr is not installed; overlap output was generated for $condition."
    fi
done <<< "$conditions"
