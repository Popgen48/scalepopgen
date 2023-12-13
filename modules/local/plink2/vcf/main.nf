process PLINK2_VCF {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    input:
    tuple val(meta), path(vcf)

    output:
    path("*.{bed,bim,fam}")    , emit: bed
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mem_mb = task.memory.toMega()
    """
    plink2 \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        $args \\
        --vcf $vcf \\
        --out ${prefix}

    #new SNP id was created so that the same positions on multiple chromosome does not break the merge-bed command 

    awk 'BEGIN{OFS="\t"}{\$2=\$1"_"\$4;print}' ${prefix}.bim > ${prefix}.1.bim

    mv ${prefix}.1.bim ${prefix}.bim

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
