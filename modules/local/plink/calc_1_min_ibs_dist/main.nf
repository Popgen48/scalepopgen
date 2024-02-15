process PLINK_CALC_1_MIN_IBS_DIST{

    tag { "1_min_ibs_distance_${new_prefix}" }
    label 'process_single'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'quay.io/biocontainers/plink:1.90b6.21--h779adbc_1' }"
    publishDir("${params.outdir}/ibs_clustering/plink/calc_1_mins_ibs_dist", mode:"copy")

    input:
        tuple val(meta), path(bed)

    output:
        path("*.mdist"), emit: mdist
        path("*.mdist.id"), emit: id
        path("*.log")


    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        prefix = meta.id
        def mem_mb = task.memory.toMega()
        outprefix = prefix+"_1_min_ibs"
	
        """
    plink \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        $args \\
        --bfile ${prefix} \\
        --out ${outprefix}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$(plink --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS

        """ 

}
