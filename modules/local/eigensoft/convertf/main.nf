process EIGENSOFT_CONVERTF{
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::eigensoft=8.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eigensoft:8.0.0--h2469040_1':
        'quay.io/biocontainers/eigensoft:8.0.0--h2469040_1' }"
    publishDir("${params.outdir}/pca/eigensoft/convertf/", mode:"copy")

    input:
    tuple val(meta), path(map), path(ped)
    path(parameter_file)

    output:
    tuple val(meta), path("*.{eigenstratgeno,snp,ind}"), emit: eigenstratgeno
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '8.0.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """

    convertf -p ${parameter_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        convertf: $VERSION
    END_VERSIONS

    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.eigenstratgeno
    touch ${prefix}.snp
    touch ${prefix}.ind

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        convertf: $VERSION
    END_VERSIONS
    """
}
