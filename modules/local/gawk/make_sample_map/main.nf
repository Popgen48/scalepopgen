process GAWK_MAKE_SAMPLE_MAP{

    tag { "making_sample_map" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/", mode:"copy")

    input:
        path(fam)
        

    output:
        path("${outprefix}.map"), emit:map

    when:
        task.ext.when == null || task.ext.when

    script:
        
        outprefix = params.outprefix
	
        """

        awk '{print \$2,\$1}' ${fam} > ${outprefix}.map

        """ 

}
