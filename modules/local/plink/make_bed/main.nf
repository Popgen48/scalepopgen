process PLINK_MAKE_BED{
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "biocontainers/plink1.9:v1.90b6.6-181012-1-deb_cv1"

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
