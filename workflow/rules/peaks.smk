# workflow/rules/peaks.smk
# ------------------------
# Peak calling with MACS2.

rule macs2_callpeak:
    input:
        chip    = lambda wc: f"{wc.outdir}/bam/{wc.sample}.filtered.bam",
        control = lambda wc: f"{wc.outdir}/bam/{get_control(wc)}.filtered.bam",
    output:
        peak    = "{outdir}/peaks/{sample}_peaks.narrowPeak",
        summit  = "{outdir}/peaks/{sample}_summits.bed",
        xls     = "{outdir}/peaks/{sample}_peaks.xls",
    params:
        name    = "{sample}",
        outdir  = "{outdir}/peaks",
        genome  = config["peak_calling"]["macs2_genome"],
        qval    = config["peak_calling"]["macs2_qvalue"],
        extra   = config["peak_calling"]["macs2_extra"],
    threads: config["threads"]["peaks"]
    log:
        "{outdir}/logs/peaks/{sample}.log",
    shell:
        """
        macs2 callpeak \
            -t {input.chip} \
            -c {input.control} \
            -f BAM \
            -g {params.genome} \
            -n {params.name} \
            --outdir {params.outdir} \
            -q {params.qval} \
            {params.extra} \
            > {log} 2>&1
        """
