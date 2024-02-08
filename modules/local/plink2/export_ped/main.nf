process PLINK2_EXPORT_PED{
    tag "merging_bed"
    label 'process_low'
    conda "bioconda::plink2==2.00a3.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"
    publishDir("${params.outdir}/pca/plink2/export_ped/", mode:"copy")

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("*.{map,ped}")    , emit: ped
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def mem_mb = task.memory.toMega()
    prefix = meta.id
    """
    
    plink2 \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        $args \\
        --bfile ${prefix} \\
        --export ped \\
        --out ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
