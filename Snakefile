"""
ChIP-seq Analysis Pipeline
==========================
Main Snakemake entry-point.

Usage
-----
    snakemake --configfile config/config.yaml --cores 16

Steps
-----
1. FastQC  – per-sample raw-read quality control
2. Trim    – adapter & quality trimming (Trim Galore)
3. Align   – read alignment to reference genome (Bowtie2)
4. Filter  – BAM sorting, duplicate marking, MAPQ filtering
5. Peaks   – peak calling (MACS2)
6. BigWig  – normalised coverage tracks (deepTools bamCoverage)
7. MultiQC – aggregated QC report
"""

from pathlib import Path
import pandas as pd


# ── configuration ──────────────────────────────────────────────────────────────
configfile: "config/config.yaml"

OUTDIR = config["outdir"]

samples_df = pd.read_csv(config["samples"], sep="\t", dtype=str).set_index(
    "sample", drop=False
)
samples_df = samples_df.fillna("")

SAMPLES = samples_df["sample"].tolist()
# ChIP samples are those that have a paired control
CHIP_SAMPLES = [s for s in SAMPLES if samples_df.loc[s, "control"] != ""]


# ── helper accessors ──────────────────────────────────────────────────────────
def get_fq1(wildcards):
    return samples_df.loc[wildcards.sample, "fq1"]


def get_fq2(wildcards):
    return samples_df.loc[wildcards.sample, "fq2"]


def get_control(wildcards):
    return samples_df.loc[wildcards.sample, "control"]


def is_paired(wildcards):
    return samples_df.loc[wildcards.sample, "fq2"] != ""


# ── target rule ───────────────────────────────────────────────────────────────
rule all:
    input:
        # FastQC on raw reads
        expand(
            "{outdir}/fastqc/{sample}_R1_fastqc.html",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # Filtered BAMs
        expand(
            "{outdir}/bam/{sample}.filtered.bam",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        expand(
            "{outdir}/bam/{sample}.filtered.bam.bai",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # Peaks for ChIP samples
        expand(
            "{outdir}/peaks/{sample}_peaks.narrowPeak",
            outdir=OUTDIR,
            sample=CHIP_SAMPLES,
        ),
        # BigWig coverage tracks
        expand(
            "{outdir}/bigwig/{sample}.bw",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # MultiQC report
        f"{OUTDIR}/multiqc/multiqc_report.html",


# ── include modular rules ─────────────────────────────────────────────────────

include: "workflow/rules/qc.smk"
include: "workflow/rules/trim.smk"
include: "workflow/rules/align.smk"
include: "workflow/rules/filter.smk"
include: "workflow/rules/peaks.smk"
include: "workflow/rules/bigwig.smk"
include: "workflow/rules/multiqc.smk"
