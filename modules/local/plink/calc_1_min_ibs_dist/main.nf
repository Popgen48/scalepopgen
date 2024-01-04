process PLINK_CALC_1_MIN_IBS_DIST{

    tag { "1_min_ibs_distance_${new_prefix}" }
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    publishDir("${params.outdir}/genetic_structure/interactive_plots/1_min_ibs_clustering/", mode:"copy")

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
        def prefix = meta.id
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
