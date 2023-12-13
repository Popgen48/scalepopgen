process PLINK2_REMOVE_CUSTOM_INDI{

    tag { "remove_indi_pca_${new_prefix}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    publishDir("${params.outdir}/plink2/remove_custom_indi_genetic_structure/", mode:"copy")

    input:
        tuple val(meta), path(bed)
        path(rem_indi)

    output:
        tuple val(n_meta), path("*_rem_indi.{bed,bim,fam}"), emit: bed
        path "versions.yml", emit: versions
        path("*.log"), emit: log

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def mem_mb = task.memory.toMega()
        def prefix = meta.id
        new_prefix = prefix + "_rem_indi"
        n_meta = [:]
        n_meta.id = new_prefix
        
        """
        plink2 \\
            --threads $task.cpus \\
            --memory $mem_mb \\
            ${args} \\
            --bfile ${prefix} \\
            --remove ${rem_indi} \\
            --out ${new_prefix}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
        END_VERSIONS

        """ 
}
