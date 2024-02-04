process IMAGEMAGIK_CONVERT{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/imagemagik:7.1.1.26' :
        'popgen48/imagemagik:7.1.1.26' }"
    publishDir("${params.outdir}/treemix/imagemagik/", mode:"copy")

    input:
        tuple val(mig), path(pdf)
        val(method)

    output:
    	tuple val(mig), path("*.png"), emit: png

    when:
     	task.ext.when == null || task.ext.when

    script:
        outprefix = method=="default" ? "Treemix_default": pdf.getName().minus(".pdf")
        
        """
        convert -density 300 -units PixelsPerInch ${pdf} ${outprefix}.png

	""" 
        

}
