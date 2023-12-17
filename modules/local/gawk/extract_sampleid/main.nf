process GAWK_EXTRACT_SAMPLEID{

    tag { "combining_indiv_summary" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/vcftools/indi_filtered/", mode:"copy")

    input:
        path(remindi)
        val(operation)

    output:
        path("*indi.txt"), emit: txt
        
    
    script:
        outprefix = params.outprefix
        def suffix = operation == "remove" ? "rem_indi.txt" : "keep_indi.txt"
        //stepdir = operation == "remove" ? "indi_filtered" : 

        """
        awk '{print \$2}' ${remindi} > ${outprefix}_${suffix}
        """ 

}
