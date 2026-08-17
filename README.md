# ChIP-seq analysis pipeline

A reproducible, sample-sheet-driven ChIP-seq workflow built from the standard tutorial pattern. The pipeline is intentionally independent from the existing Streamlit app in the parent repository.

## Workflow

`FASTQ -> FastQC/fastp -> Bowtie2 -> sorted/indexed BAM -> MACS3 peaks -> deepTools signal tracks -> R QC report`

The template supports paired-end FASTQ files and one or more ChIP/Input pairs. It expects tools to be installed through Conda/Mamba.

## Quick start

```bash
cd chipseq_pipeline
mamba env create -f environment.yml
mamba activate chipseq

# Edit config.tsv and samples.tsv first.
# Set the reference index prefix in config.tsv.
./run_chipseq.sh --config config.tsv --samples samples.tsv --threads 8
```

For a dry run:

```bash
./run_chipseq.sh --config config.tsv --samples samples.tsv --dry-run
```

## Input files

`config.tsv` contains project-level paths and parameters. `samples.tsv` contains one row per library:

| sample | condition | replicate | type | fastq_r1 | fastq_r2 |
|---|---|---:|---|---|---|
| chip_treat_rep1 | treat | 1 | chip | data/chip_treat_rep1_R1.fastq.gz | data/chip_treat_rep1_R2.fastq.gz |
| input_treat_rep1 | treat | 1 | input | data/input_treat_rep1_R1.fastq.gz | data/input_treat_rep1_R2.fastq.gz |

`type` must be `chip` or `input`. Each ChIP library must have a matching Input library with the same `condition` and `replicate`.

## Important setup

1. Download the Bowtie2 index for the correct genome and set `BOWTIE2_INDEX` to its prefix, for example `/refs/hg38/bowtie2/hg38`.
2. Set `GENOME_SIZE` for MACS3 (`hs`, `mm`, or an explicit effective genome size).
3. Confirm that FASTQ paths, read layout, and peak model settings match the experiment.
4. Run FastQC and inspect mapping/duplication metrics before interpreting peaks.

## Outputs

- `results/qc/`: FastQC, fastp reports, multiQC report, and R QC plots
- `results/bam/`: sorted/indexed BAM files and flagstat summaries
- `results/peaks/`: MACS3 narrowPeak files, summits, and peak tables
- `results/bigwig/`: normalized CPM bigWig tracks
- `results/logs/`: command logs for each stage

## Caveats

This is a transparent teaching/research template, not a replacement for project-specific review. Peak calling parameters, blacklist filtering, biological replicate handling, and differential binding analysis should be adapted to the assay and organism. Do not interpret peaks until read quality, alignment, library complexity, and Input controls have been reviewed.

## Suggested GitHub repository layout

```text
chipseq_pipeline/
├── config.tsv
├── samples.tsv
├── environment.yml
├── run_chipseq.sh
├── scripts/
│   ├── 01_qc_trim.sh
│   ├── 02_align_bam.sh
│   ├── 03_call_peaks.sh
│   └── 04_signal_tracks.sh
└── R/
    └── plot_qc.R
```
