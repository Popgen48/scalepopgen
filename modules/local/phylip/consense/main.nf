process PHYLIP_CONSENSE{

    tag { "consense" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/phylip:3.697' :
        'popgen48/phylip:3.697' }"
    publishDir("${params.outdir}/treemix/phylip/consense", mode:"copy")

    input:
        path(trees)

    output:
        path("out*")

    when:
     task.ext.when == null || task.ext.when

    script:
        

        """
	zcat ${trees} > treemixBootstrapped.trees
	
	phylip consense << inputStarts
	treemixBootstrapped.trees
	Y
	inputStarts

        """ 

}
