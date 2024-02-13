process PLINK2_CALC_PAIRWISE_FST{

    tag { "pairwise_fst_${prefix}" }
    label "process_single"
    conda "bioconda::plink2==2.00a3.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'quay.io/biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"
    publishDir("${params.outdir}/fst_clustering/plink2", mode:"copy")

    input:
        tuple val(meta), path(bed)
        path(cluster_file)
        

    output:
        path("*.log"), emit:log
        path("*.fst.summary"), emit: fst_mat
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def mem_mb = task.memory.toMega()
        def prefix = meta.id


	
        """
        plink2 \\
            --threads $task.cpus \\
            --memory $mem_mb \\
            ${args} \\
            --bfile ${prefix} \\
            --within ${cluster_file} \\
            --fst CATPHENO method=wc \\
            --out ${prefix}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
        END_VERSIONS


        """ 

}
