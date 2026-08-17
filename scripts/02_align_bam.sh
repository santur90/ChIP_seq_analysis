#!/usr/bin/env bash
set -euo pipefail

samples=$1
index=$2
trimmed=$3
outdir=$4
threads=$5

mkdir -p "$outdir" "$outdir/logs"

tail -n +2 "$samples" | while IFS=$'\t' read -r sample condition replicate type r1 r2; do
    [[ -n "$sample" ]] || continue
    read1="$trimmed/${sample}_R1.fastq.gz"
    read2="$trimmed/${sample}_R2.fastq.gz"
    bam="$outdir/${sample}.sorted.bam"
    [[ -f "$read1" && -f "$read2" ]] || { echo "Trimmed reads missing for $sample" >&2; exit 1; }

    bowtie2 -x "$index" -1 "$read1" -2 "$read2" -p "$threads" \
        2> "$outdir/logs/${sample}.bowtie2.log" \
        | samtools view -@ "$threads" -b -q 30 \
        | samtools sort -@ "$threads" -o "$bam" -
    samtools index -@ "$threads" "$bam"
    samtools flagstat -@ "$threads" "$bam" > "$outdir/${sample}.flagstat.txt"
done
