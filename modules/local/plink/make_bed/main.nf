process PLINK_MAKE_BED{
    tag "$meta.id"
    label 'process_single'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'quay.io/biocontainers/plink:1.90b6.21--h779adbc_1' }"
    publishDir("${params.outdir}/plink/make_bed/", mode:"copy")

    input:
    tuple val(meta), path(bed)
    path(chrom_map)

    output:
    tuple val(n_meta), path("*.{bed,bim,fam}")    , emit: bed
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = meta.id
    def mem_mb = task.memory.toMega()
    n_meta = [:]
    outprefix = prefix+"_update_chrom_id"
    n_meta.id = outprefix

    """
    plink \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        $args \\
        --bfile ${prefix} \\
        --update-chr ${chrom_map} \\
        --out ${outprefix}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$(plink --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
