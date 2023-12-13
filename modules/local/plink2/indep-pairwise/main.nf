process PLINK2_INDEP_PAIRWISE{

    tag { "ld_filtering_${new_prefix}" }
    label "oneCpu"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"
    publishDir("${params.outdir}/plink/ld_filtering/", mode:"copy")

    input:
        tuple val(meta), file(bed)

    output:
        tuple val(meta_n), path("*ld_filtered.{bed,bim,fam}"), emit: bed
        path("*.log")
        path("*prune*")

    when:
        task.ext.when == null || task.ext.when

    script:

        def args = task.ext.args ?: ''
        def args2 = task.ext.args2 ?: ''
        prefix = meta.id
        def mem_mb = task.memory.toMega()
        meta_n = [:]
        meta_n.id = prefix+"_ld_filtered"


	
        """
       plink2 \\
        --threads $task.cpus \\
        --memory $mem_mb \\
         ${args} \\
        --bfile ${prefix} \\
        --indep-pairwise ${args2} \\

       plink2 \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        ${args} \\
        --bfile ${prefix} \\
        --extract plink2.prune.in \\
        --out ${prefix}_ld_filtered
        

        """ 

}
