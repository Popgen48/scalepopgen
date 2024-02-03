process IMAGEMAGIK{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/imagemagik:7.1.1.26' :
        'popgen48/imagemagik:7.1.1.26' }"
    publishDir("${params.outdir}/treemix/imagemagik/", mode:"copy")

    input:
        path(pdf)

    output:
    	path("*_mqc.png"), emit: png

    when:
     	task.ext.when == null || task.ext.when

    script:
        outprefix = pdf.getName().minus(".pdf")
        
        
        """
        convert -density 300 -units PixelsPerInch ${pdf} Treemix_mqc.png

	""" 
        

}
