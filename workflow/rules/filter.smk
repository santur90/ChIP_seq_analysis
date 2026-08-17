# workflow/rules/filter.smk
# -------------------------
# Mark duplicates, filter by MAPQ, and optionally remove blacklisted regions.

rule mark_duplicates:
    """Mark PCR duplicates with samtools markdup."""
    input:
        bam = "{outdir}/bam/{sample}.raw.bam",
        bai = "{outdir}/bam/{sample}.raw.bam.bai",
    output:
        bam     = "{outdir}/bam/{sample}.markdup.bam",
        metrics = "{outdir}/bam/{sample}.markdup.txt",
    threads: config["threads"]["dedup"]
    log:
        "{outdir}/logs/filter/{sample}.markdup.log",
    shell:
        """
        samtools markdup \
            -@ {threads} \
            -s \
            --write-index \
            -f {output.metrics} \
            {input.bam} \
            {output.bam} \
            > {log} 2>&1
        """


rule filter_bam:
    """
    Remove:
      * unmapped reads  (-F 4)
      * secondary/supplementary alignments  (-F 2048 -F 256)
      * PCR duplicates  (-F 1024)
      * low MAPQ reads  (-q MAPQ)
    Optionally intersect with blacklist.
    """
    input:
        bam = "{outdir}/bam/{sample}.markdup.bam",
    output:
        bam = "{outdir}/bam/{sample}.filtered.bam",
        bai = "{outdir}/bam/{sample}.filtered.bam.bai",
    params:
        mapq      = config["alignment"]["mapq_filter"],
        blacklist = config["genome"]["blacklist"],
    threads: config["threads"]["sort"]
    log:
        "{outdir}/logs/filter/{sample}.filter.log",
    run:
        bl = params.blacklist
        if bl:
            shell(
                "( samtools view -@ {threads} -b "
                "-F 3332 -q {params.mapq} {input.bam} "
                "| bedtools intersect -v -abam stdin -b {bl} "
                "| samtools sort -@ {threads} -o {output.bam} "
                "&& samtools index {output.bam} "
                ") > {log} 2>&1"
            )
        else:
            shell(
                "( samtools view -@ {threads} -b "
                "-F 3332 -q {params.mapq} {input.bam} "
                "| samtools sort -@ {threads} -o {output.bam} "
                "&& samtools index {output.bam} "
                ") > {log} 2>&1"
            )
