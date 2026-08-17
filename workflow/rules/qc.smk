# workflow/rules/qc.smk
# ---------------------
# FastQC on raw (pre-trimming) reads.

rule fastqc_raw:
    input:
        r1 = get_fq1,
    output:
        html = "{outdir}/fastqc/{sample}_R1_fastqc.html",
        zip  = "{outdir}/fastqc/{sample}_R1_fastqc.zip",
    params:
        outdir = "{outdir}/fastqc",
    threads: config["threads"]["fastqc"]
    log:
        "{outdir}/logs/fastqc/{sample}.log",
    shell:
        "fastqc -t {threads} -o {params.outdir} {input.r1} > {log} 2>&1"
