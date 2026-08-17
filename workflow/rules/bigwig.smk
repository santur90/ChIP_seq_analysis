# workflow/rules/bigwig.smk
# -------------------------
# Generate normalised BigWig coverage tracks with deepTools bamCoverage.

rule bamcoverage:
    input:
        bam = "{outdir}/bam/{sample}.filtered.bam",
        bai = "{outdir}/bam/{sample}.filtered.bam.bai",
    output:
        bw = "{outdir}/bigwig/{sample}.bw",
    params:
        binsize    = config["bigwig"]["binsize"],
        normalise  = config["bigwig"]["normalise"],
        blacklist  = config["genome"]["blacklist"],
    threads: config["threads"]["bigwig"]
    log:
        "{outdir}/logs/bigwig/{sample}.log",
    run:
        bl_flag = f"--blackListFileName {params.blacklist}" if params.blacklist else ""
        shell(
            "bamCoverage "
            "-b {input.bam} "
            "-o {output.bw} "
            "--binSize {params.binsize} "
            "--normalizeUsing {params.normalise} "
            f"{bl_flag} "
            "-p {threads} "
            "> {log} 2>&1"
        )
