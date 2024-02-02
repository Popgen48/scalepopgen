process PYTHON_PDF2IMAGE{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/pdf2image:1.17.0' :
        'popgen48/pdf2image:1.17.0' }"
    publishDir("${params.outdir}/treemix/python/pdf2image/", mode:"copy")

    input:
        path(pdf)

    output:
    	path("*.jpg"), emit: jpg

    when:
     	task.ext.when == null || task.ext.when

    script:
        outprefix = pdf.getName().minus(".pdf")
        
        
        """

	python3 ${baseDir}/bin/pdf2image.py ${pdf} ${outprefix}


	""" 
        

}
