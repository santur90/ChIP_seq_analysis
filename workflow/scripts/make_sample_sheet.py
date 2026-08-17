#!/usr/bin/env python3
"""
scripts/make_sample_sheet.py
-----------------------------
Scan a directory for paired-end FASTQ files and generate a samples.tsv
skeleton ready for editing.

Naming convention expected: <sample>_R1.fastq.gz / <sample>_R2.fastq.gz
(or <sample>_R1_001.fastq.gz etc.)

Usage
-----
    python workflow/scripts/make_sample_sheet.py \
        --fastq_dir data/ \
        --output config/samples.tsv
"""

import argparse
import os
import re
import sys
from pathlib import Path


def parse_args():
    p = argparse.ArgumentParser(description="Generate a ChIP-seq sample sheet.")
    p.add_argument("--fastq_dir", required=True, help="Directory containing FASTQ files.")
    p.add_argument("--output",    default="config/samples.tsv", help="Output TSV path.")
    return p.parse_args()


def collect_samples(fastq_dir):
    samples = {}
    pattern = re.compile(r"^(.+?)_R?(1|2)(?:_\d+)?\.fastq(?:\.gz)?$")
    for fname in sorted(os.listdir(fastq_dir)):
        m = pattern.match(fname)
        if not m:
            continue
        name, read = m.group(1), m.group(2)
        path = os.path.join(fastq_dir, fname)
        samples.setdefault(name, {})
        samples[name][f"r{read}"] = path
    return samples


def main():
    args = parse_args()
    fastq_dir = Path(args.fastq_dir)
    if not fastq_dir.is_dir():
        sys.exit(f"ERROR: Directory not found: {fastq_dir}")

    samples = collect_samples(fastq_dir)
    if not samples:
        sys.exit(f"No FASTQ files found matching expected naming convention in {fastq_dir}")

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w") as fh:
        fh.write("sample\tcontrol\tfq1\tfq2\n")
        for name, reads in sorted(samples.items()):
            r1 = reads.get("r1", "")
            r2 = reads.get("r2", "")
            fh.write(f"{name}\t\t{r1}\t{r2}\n")

    print(f"Sample sheet written to {out_path}")
    print(f"  {len(samples)} samples detected.")
    print("Edit the 'control' column before running the pipeline.")


if __name__ == "__main__":
    main()
