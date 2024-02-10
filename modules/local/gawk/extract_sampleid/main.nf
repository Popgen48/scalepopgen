process GAWK_EXTRACT_SAMPLEID{

    tag { "combining_indiv_summary" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/${operation}/gawk/filtering/", mode:"copy")

    input:
        path(remindi)
        val(operation)

    output:
        path("*indi.txt"), emit: txt
        path "versions.yml", emit: versions
       
    
    script:
        outprefix = params.outprefix
        def suffix = operation == "sample_filtering" ? "rem_indi.txt" : "keep_indi.txt"
        //stepdir = operation == "remove" ? "indi_filtered" : 

        """
    awk '{print \$2}' ${remindi} > ${outprefix}_${suffix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS
        """ 

}
