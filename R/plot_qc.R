#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: plot_qc.R <bam_dir> <output_png>")
suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
  library(dplyr)
  library(tidyr)
})

bam_dir <- args[[1]]
output_png <- args[[2]]
files <- list.files(bam_dir, pattern = "\\.flagstat\\.txt$", full.names = TRUE)
if (length(files) == 0) stop("No samtools flagstat files found in ", bam_dir)

parse_flagstat <- function(path) {
  lines <- readLines(path, warn = FALSE)
  mapped <- grep("mapped ", lines, value = TRUE, fixed = TRUE)[1]
  properly_paired <- grep("properly paired", lines, value = TRUE, fixed = TRUE)[1]
  get_percent <- function(line) {
    if (is.na(line)) return(NA_real_)
    as.numeric(sub(".*\\(([0-9.]+)%\\).*", "\\1", line))
  }
  tibble(
    sample = sub("\\.flagstat\\.txt$", "", basename(path)),
    mapped_percent = get_percent(mapped),
    properly_paired_percent = get_percent(properly_paired)
  )
}

qc <- bind_rows(lapply(files, parse_flagstat))
write_tsv(qc, sub("\\.png$", ".tsv", output_png))
long_qc <- pivot_longer(qc, cols = c(mapped_percent, properly_paired_percent), names_to = "metric", values_to = "percent")
plot <- ggplot(long_qc, aes(x = sample, y = percent, fill = metric)) +
  geom_col(position = "dodge") +
  coord_cartesian(ylim = c(0, 100)) +
  labs(title = "ChIP-seq alignment QC", x = NULL, y = "Percent") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(output_png, plot, width = 9, height = 5, dpi = 150)
