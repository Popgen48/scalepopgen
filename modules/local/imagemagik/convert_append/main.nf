process IMAGEMAGIK_CONVERT_APPEND{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/imagemagik:7.1.1.26' :
        'popgen48/imagemagik:7.1.1.26' }"
    publishDir("${params.outdir}/treemix/imagemagik/", mode:"copy")

    input:
        tuple val(mig), path(png)

    output:
    	path("${outprefix}.png"), emit: png

    when:
     	task.ext.when == null || task.ext.when

    script:
        outprefix = "Treemix_m"+mig
        
        
        """
        convert +append ${png} ${outprefix}.png

	""" 
        

}
