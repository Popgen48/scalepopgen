process PLINK2_INDEP_PAIRWISE{

    tag { "ld_filtering_${prefix}" }
    label "process_single"
    conda "bioconda::plink2==2.00a3.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'quay.io/biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"
    publishDir("${params.outdir}/plink2/ld_filtering/", mode:"copy")

    input:
        tuple val(meta), file(bed)

    output:
        tuple val(meta_n), path("*ld_filtered.{bed,bim,fam}"), emit: bed
        path("*.log")
        path("*prune*")
        path "versions.yml", emit: versions

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
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS

        """ 

}
