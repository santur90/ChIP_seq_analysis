#!/usr/bin/env python3
"""
scripts/build_bowtie2_index.py
-------------------------------
Helper script: build a Bowtie2 genome index from a FASTA file.

Usage
-----
    python workflow/scripts/build_bowtie2_index.py \
        --fasta resources/genome.fa \
        --prefix resources/bowtie2_index/genome \
        --threads 8
"""

import argparse
import os
import subprocess
import sys


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build a Bowtie2 genome index."
    )
    parser.add_argument("--fasta",   required=True, help="Input genome FASTA file.")
    parser.add_argument("--prefix",  required=True, help="Output index prefix.")
    parser.add_argument("--threads", type=int, default=4, help="Number of threads.")
    return parser.parse_args()


def main():
    args = parse_args()

    if not os.path.isfile(args.fasta):
        sys.exit(f"ERROR: FASTA file not found: {args.fasta}")

    index_dir = os.path.dirname(args.prefix)
    if index_dir:
        os.makedirs(index_dir, exist_ok=True)

    cmd = [
        "bowtie2-build",
        "--threads", str(args.threads),
        args.fasta,
        args.prefix,
    ]
    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(f"ERROR: bowtie2-build failed with exit code {result.returncode}")
    print("Index built successfully.")


if __name__ == "__main__":
    main()
