# workflow/rules/multiqc.smk
# --------------------------
# Aggregate all QC outputs into a single MultiQC report.

rule multiqc:
    input:
        # FastQC on raw reads
        expand(
            "{outdir}/fastqc/{sample}_R1_fastqc.zip",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # Trim Galore logs
        expand(
            "{outdir}/logs/trim/{sample}.log",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # Alignment logs
        expand(
            "{outdir}/logs/align/{sample}.log",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
        # markdup metrics
        expand(
            "{outdir}/bam/{sample}.markdup.txt",
            outdir=OUTDIR,
            sample=SAMPLES,
        ),
    output:
        report = "{outdir}/multiqc/multiqc_report.html",
        data   = directory("{outdir}/multiqc/multiqc_data"),
    params:
        indir  = OUTDIR,
        outdir = "{outdir}/multiqc",
    log:
        "{outdir}/logs/multiqc.log",
    shell:
        """
        multiqc \
            {params.indir} \
            --outdir {params.outdir} \
            --force \
            > {log} 2>&1
        """
