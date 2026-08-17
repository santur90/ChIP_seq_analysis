# ChIP-seq Analysis Pipeline

A reproducible, Snakemake-based pipeline for ChIP-seq data analysis covering
quality control, adapter trimming, alignment, duplicate removal, peak calling,
and signal-track generation.

---

## Table of Contents

1. [Overview](#overview)
2. [Pipeline Steps](#pipeline-steps)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Quick Start](#quick-start)
6. [Configuration](#configuration)
7. [Input Files](#input-files)
8. [Output Structure](#output-structure)
9. [Helper Scripts](#helper-scripts)

---

## Overview

```
Raw FASTQ
   │
   ▼
FastQC (raw-read QC)
   │
   ▼
Trim Galore (adapter & quality trimming)
   │
   ▼
Bowtie2 (alignment to reference genome)
   │
   ▼
Samtools markdup + filter (duplicate marking, MAPQ filter, blacklist removal)
   │
   ├─► MACS2 (peak calling – ChIP vs. Input)
   │
   ├─► deepTools bamCoverage (normalised BigWig tracks)
   │
   └─► MultiQC (aggregated QC report)
```

---

## Pipeline Steps

| Step | Tool | Description |
|------|------|-------------|
| 1 | FastQC | Per-sample quality metrics on raw reads |
| 2 | Trim Galore | Adapter and low-quality-base trimming |
| 3 | Bowtie2 | Short-read alignment to reference genome |
| 4 | Samtools markdup | Mark PCR duplicates |
| 5 | Samtools view | Filter by MAPQ and remove blacklisted regions |
| 6 | MACS2 | Peak calling (narrow peaks) |
| 7 | deepTools | Normalised RPKM BigWig tracks |
| 8 | MultiQC | Aggregate all QC logs into one HTML report |

---

## Requirements

- [Conda](https://docs.conda.io/) / [Mamba](https://github.com/mamba-org/mamba) (recommended)
- Snakemake ≥ 7.0

All other tools are installed automatically via the provided Conda environment.

---

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/santur90/ChIP_seq_analysis.git
cd ChIP_seq_analysis

# 2. Create and activate the Conda environment
conda env create -f environment.yaml
conda activate chipseq
```

---

## Quick Start

```bash
# 1. Generate a sample sheet skeleton from your FASTQ directory
python workflow/scripts/make_sample_sheet.py \
    --fastq_dir data/ \
    --output config/samples.tsv

# 2. Edit config/samples.tsv – fill in the 'control' column
#    (leave blank for Input/control samples)

# 3. Build a Bowtie2 index (skip if you already have one)
python workflow/scripts/build_bowtie2_index.py \
    --fasta resources/genome.fa \
    --prefix resources/bowtie2_index/genome \
    --threads 8

# 4. Edit config/config.yaml to point to your index and set parameters

# 5. Dry-run to check the workflow
snakemake --configfile config/config.yaml --cores 16 -n

# 6. Run the pipeline
snakemake --configfile config/config.yaml --cores 16
```

---

## Configuration

All parameters live in **`config/config.yaml`**:

| Parameter | Description |
|-----------|-------------|
| `samples` | Path to the sample sheet TSV |
| `genome.fasta` | Reference genome FASTA |
| `genome.bowtie2_index` | Bowtie2 index prefix |
| `genome.blacklist` | BED file of blacklisted regions (optional) |
| `trimming.adapter_r1/r2` | Illumina adapter sequences |
| `trimming.quality` | Minimum Phred score for trimming |
| `trimming.min_length` | Minimum read length after trimming |
| `alignment.bowtie2_extra` | Extra flags for Bowtie2 |
| `alignment.mapq_filter` | Minimum MAPQ to retain |
| `peak_calling.macs2_genome` | MACS2 genome size (`hs`, `mm`, …) |
| `peak_calling.macs2_qvalue` | MACS2 q-value cutoff |
| `peak_calling.macs2_extra` | Extra flags for MACS2 |
| `threads.*` | Per-rule thread counts |

---

## Input Files

### Sample Sheet (`config/samples.tsv`)

A tab-separated file with four columns:

| Column | Description |
|--------|-------------|
| `sample` | Unique sample name |
| `control` | Name of the paired Input/control sample (blank for Input samples) |
| `fq1` | Path to R1 FASTQ (can be gzipped) |
| `fq2` | Path to R2 FASTQ (paired-end; blank for single-end) |

Example:

```tsv
sample          control         fq1                             fq2
H3K4me3_rep1    Input_rep1      data/H3K4me3_rep1_R1.fastq.gz  data/H3K4me3_rep1_R2.fastq.gz
H3K4me3_rep2    Input_rep2      data/H3K4me3_rep2_R1.fastq.gz  data/H3K4me3_rep2_R2.fastq.gz
Input_rep1                      data/Input_rep1_R1.fastq.gz    data/Input_rep1_R2.fastq.gz
Input_rep2                      data/Input_rep2_R1.fastq.gz    data/Input_rep2_R2.fastq.gz
```

---

## Output Structure

```
results/
├── fastqc/                  # FastQC HTML/zip reports (raw reads)
├── trimmed/                 # Trimmed FASTQ files + post-trim FastQC
├── bam/
│   ├── *.raw.bam            # Raw Bowtie2 alignments
│   ├── *.markdup.bam        # Duplicate-marked BAMs
│   ├── *.filtered.bam       # Final filtered BAMs (+ .bai indices)
│   └── *.markdup.txt        # Duplicate metrics
├── peaks/
│   ├── *_peaks.narrowPeak   # MACS2 narrow peaks
│   ├── *_summits.bed        # MACS2 peak summits
│   └── *_peaks.xls          # MACS2 peak statistics
├── bigwig/
│   └── *.bw                 # RPKM-normalised BigWig tracks
├── multiqc/
│   └── multiqc_report.html  # Aggregated QC report
└── logs/                    # Per-rule log files
```

---

## Helper Scripts

| Script | Description |
|--------|-------------|
| `workflow/scripts/make_sample_sheet.py` | Auto-generate `samples.tsv` from a FASTQ directory |
| `workflow/scripts/build_bowtie2_index.py` | Build a Bowtie2 genome index |