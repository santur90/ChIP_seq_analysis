# workflow/rules/trim.smk
# -----------------------
# Adapter and quality trimming with Trim Galore.
# Supports both single-end (fq2 == "") and paired-end reads.

def _trim_input(wildcards):
    r1 = samples_df.loc[wildcards.sample, "fq1"]
    r2 = samples_df.loc[wildcards.sample, "fq2"]
    if r2:
        return [r1, r2]
    return [r1]


rule trim_galore_pe:
    """Paired-end trimming."""
    input:
        _trim_input,
    output:
        r1   = "{outdir}/trimmed/{sample}_val_1.fq.gz",
        r2   = "{outdir}/trimmed/{sample}_val_2.fq.gz",
        qc_r1 = "{outdir}/trimmed/{sample}_R1_fastqc.html",
        qc_r2 = "{outdir}/trimmed/{sample}_R2_fastqc.html",
    params:
        outdir   = "{outdir}/trimmed",
        adapter1 = config["trimming"]["adapter_r1"],
        adapter2 = config["trimming"]["adapter_r2"],
        quality  = config["trimming"]["quality"],
        minlen   = config["trimming"]["min_length"],
    threads: config["threads"]["trim"]
    log:
        "{outdir}/logs/trim/{sample}.log",
    shell:
        """
        trim_galore \
            --paired \
            --adapter {params.adapter1} \
            --adapter2 {params.adapter2} \
            --quality {params.quality} \
            --length {params.minlen} \
            --fastqc \
            --cores {threads} \
            --output_dir {params.outdir} \
            {input} \
            > {log} 2>&1
        """


rule trim_galore_se:
    """Single-end trimming."""
    input:
        _trim_input,
    output:
        r1   = "{outdir}/trimmed/{sample}_trimmed.fq.gz",
        qc_r1 = "{outdir}/trimmed/{sample}_fastqc.html",
    params:
        outdir  = "{outdir}/trimmed",
        adapter = config["trimming"]["adapter_r1"],
        quality = config["trimming"]["quality"],
        minlen  = config["trimming"]["min_length"],
    threads: config["threads"]["trim"]
    log:
        "{outdir}/logs/trim/{sample}.log",
    shell:
        """
        trim_galore \
            --adapter {params.adapter} \
            --quality {params.quality} \
            --length {params.minlen} \
            --fastqc \
            --cores {threads} \
            --output_dir {params.outdir} \
            {input} \
            > {log} 2>&1
        """
