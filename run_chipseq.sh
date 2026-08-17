#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config="$script_dir/config.tsv"
samples="$script_dir/samples.tsv"
dry_run=false

usage() {
    echo "Usage: $0 [--config FILE] [--samples FILE] [--threads N] [--dry-run]"
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        --config) config=$2; shift 2 ;;
        --samples) samples=$2; shift 2 ;;
        --threads) cli_threads=$2; shift 2 ;;
        --dry-run) dry_run=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

get_config() { awk -F '\t' -v key="$1" '$1 == key {print $2; exit}' "$config"; }
threads=${cli_threads:-$(get_config THREADS)}
index=$(get_config BOWTIE2_INDEX)
genome_size=$(get_config GENOME_SIZE)
effective_genome_size=$(get_config EFFECTIVE_GENOME_SIZE)
outdir=$(get_config OUTDIR)

for value in "$threads" "$index" "$genome_size" "$effective_genome_size" "$outdir"; do
    [[ -n "$value" ]] || { echo "Incomplete config: check $config" >&2; exit 1; }
done
[[ -f "$samples" ]] || { echo "Sample sheet not found: $samples" >&2; exit 1; }

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    if [[ "$dry_run" == false ]]; then "$@"; fi
}

qc_dir="$script_dir/$outdir/qc"
bam_dir="$script_dir/$outdir/bam"
peak_dir="$script_dir/$outdir/peaks"
bigwig_dir="$script_dir/$outdir/bigwig"
mkdir -p "$script_dir/$outdir/logs"

run bash "$script_dir/scripts/01_qc_trim.sh" "$samples" "$qc_dir" "$threads"
run bash "$script_dir/scripts/02_align_bam.sh" "$samples" "$index" "$qc_dir/trimmed" "$bam_dir" "$threads"
run bash "$script_dir/scripts/03_call_peaks.sh" "$samples" "$bam_dir" "$peak_dir" "$genome_size" "$threads"
run bash "$script_dir/scripts/04_signal_tracks.sh" "$samples" "$bam_dir" "$bigwig_dir" "$effective_genome_size" "$threads"
run multiqc "$script_dir/$outdir" --outdir "$qc_dir/multiqc"
run Rscript "$script_dir/R/plot_qc.R" "$bam_dir" "$qc_dir/alignment_qc.png"

echo "Pipeline complete: $script_dir/$outdir"
