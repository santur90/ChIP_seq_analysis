# workflow/rules/align.smk
# ------------------------
# Alignment to the reference genome with Bowtie2.
# Produces a coordinate-sorted BAM.

def _align_input(wildcards):
    r2 = samples_df.loc[wildcards.sample, "fq2"]
    if r2:
        return {
            "r1": f"{OUTDIR}/trimmed/{wildcards.sample}_val_1.fq.gz",
            "r2": f"{OUTDIR}/trimmed/{wildcards.sample}_val_2.fq.gz",
        }
    return {"r1": f"{OUTDIR}/trimmed/{wildcards.sample}_trimmed.fq.gz"}


rule bowtie2_align:
    input:
        unpack(_align_input),
    output:
        bam = "{outdir}/bam/{sample}.raw.bam",
        bai = "{outdir}/bam/{sample}.raw.bam.bai",
    params:
        index = config["genome"]["bowtie2_index"],
        extra = config["alignment"]["bowtie2_extra"],
        reads = lambda wildcards, input: (
            f"-1 {input.r1} -2 {input.r2}"
            if hasattr(input, "r2") and input.r2
            else f"-U {input.r1}"
        ),
    threads: config["threads"]["align"]
    log:
        "{outdir}/logs/align/{sample}.log",
    shell:
        """
        ( bowtie2 \
            -p {threads} \
            -x {params.index} \
            {params.reads} \
            {params.extra} \
        | samtools sort -@ {threads} -o {output.bam} \
        && samtools index {output.bam} ) \
        > {log} 2>&1
        """
