#!/usr/bin/env bash
set -euo pipefail

samples=$1
index=$2
trimmed=$3
outdir=$4
threads=$5
alignment_mode=$6
min_mapq=$7
remove_duplicates=$8
unique_only=$9
blacklist=${10:-}

mkdir -p "$outdir" "$outdir/intermediate" "$outdir/logs"

tail -n +2 "$samples" | while IFS=$'\t' read -r sample _ _ _ _ _; do
    [[ -n "$sample" ]] || continue
    read1="$trimmed/${sample}_R1.fastq.gz"
    read2="$trimmed/${sample}_R2.fastq.gz"
    sam="$outdir/intermediate/${sample}.unsorted.sam"
    name_sorted="$outdir/intermediate/${sample}.name_sorted.bam"
    fixmate="$outdir/intermediate/${sample}.fixmate.bam"
    coordinate_sorted="$outdir/intermediate/${sample}.coordinate_sorted.bam"
    bam="$outdir/${sample}.filtered.bam"
    [[ -f "$read1" && -f "$read2" ]] || { echo "Trimmed reads missing for $sample" >&2; exit 1; }

    bowtie_args=(bowtie2 -x "$index" -1 "$read1" -2 "$read2" -p "$threads" -S "$sam")
    [[ "$alignment_mode" == "local" ]] && bowtie_args+=(--local)
    [[ "$alignment_mode" == "end-to-end" ]] && bowtie_args+=(--end-to-end)
    "${bowtie_args[@]}" \
        2> "$outdir/logs/${sample}.bowtie2.log" \
    samtools view -@ "$threads" -h -q "$min_mapq" -F 4 "$sam" \
        | awk -v unique="$unique_only" 'BEGIN { OFS="\t" } /^@/ { print; next } { has_xs=0; for (i=12; i<=NF; i++) if ($i ~ /^XS:/) has_xs=1; if (unique != "true" || has_xs == 0) print }' \
        | samtools view -@ "$threads" -b - \
        | samtools sort -@ "$threads" -n -o "$name_sorted" -

    samtools fixmate -@ "$threads" -m "$name_sorted" "$fixmate"
    samtools sort -@ "$threads" -o "$coordinate_sorted" "$fixmate"
    if [[ "$remove_duplicates" == "true" ]]; then
        samtools markdup -@ "$threads" -r "$coordinate_sorted" "$bam"
    else
        cp "$coordinate_sorted" "$bam"
    fi
    if [[ -n "$blacklist" ]]; then
        [[ -f "$blacklist" ]] || { echo "Blacklist BED not found: $blacklist" >&2; exit 1; }
        bedtools intersect -v -abam "$bam" -b "$blacklist" > "$outdir/${sample}.blacklist_filtered.bam"
        mv "$outdir/${sample}.blacklist_filtered.bam" "$bam"
    fi
    samtools index -@ "$threads" "$bam"
    samtools flagstat -@ "$threads" "$bam" > "$outdir/${sample}.flagstat.txt"
    samtools stats "$bam" > "$outdir/${sample}.stats.txt"
done
