# ChIP_seq_analysis

A reproducible, sample-sheet-driven ChIP-seq workflow for paired-end sequencing data. 

## Workflow

`FASTQ -> FastQC/fastp -> Bowtie2 local alignment -> unique/high-quality BAM -> MACS3 peaks -> replicate QC -> signal tracks`

The workflow supports paired-end FASTQ files and one or more ChIP/Input pairs. Software is managed through Conda/Mamba.

## Quick start

```bash
cd chipseq_pipeline
mamba env create -f environment.yml
mamba activate chipseq

# Edit config.tsv and samples.tsv before running.
# Set the reference index prefix and optional QC paths in config.tsv.
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

## Configuration

1. Set `BOWTIE2_INDEX` to the Bowtie2 index prefix, for example `/refs/hg38/bowtie2/hg38`.
2. Set `GENOME_SIZE` for MACS3 (`hs`, `mm`, or an explicit effective genome size).
3. `ALIGNMENT_MODE=local` enables soft clipping for adapter or low-quality sequence at read ends.
4. `UNIQUE_ONLY=true` removes alignments carrying the Bowtie2 `XS` secondary-alignment tag.
5. `REMOVE_DUPLICATES=true` removes marked PCR duplicates with `samtools markdup`.
6. Set `BLACKLIST_BED` to a genome-version-matched blacklist BED file to enable blacklist filtering.
7. Set `PHANTOMPEAK_SCRIPT` to a local `run_spp.R` path to enable strand cross-correlation metrics.
8. Set `REGIONS_BED` to a BED file to generate TSS profile and heatmap figures.

## Outputs

- `results/qc/`: FastQC, fastp, MultiQC, alignment summaries, and optional cross-correlation output
- `results/bam/`: intermediate SAM/BAM files, final filtered/indexed BAM files, and alignment metrics
- `results/peaks/`: MACS3 narrowPeak, summit, and peak table files
- `results/replicates/`: peak overlaps and optional IDR output for biological replicates
- `results/bigwig/`: normalized CPM bigWig tracks
- `results/visualization/`: ChIP/Input log2-ratio tracks and optional TSS plots
- `results/logs/`: command logs for each stage

## Caveats

Peak calling parameters, blacklist filtering, biological replicate handling, and differential binding analysis should be adapted to the assay and organism. Review read quality, alignment, library complexity, replicate concordance, and Input controls before interpreting peaks. All coordinate files must use the same genome assembly.

## Repository layout

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
│   ├── 04_signal_tracks.sh
│   ├── 05_cross_correlation.sh
│   ├── 06_replicate_consistency.sh
│   └── 07_visualization.sh
└── R/
    └── plot_qc.R
```
