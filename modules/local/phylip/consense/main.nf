process PHYLIP_CONSENSE{

    tag { "consense" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/phylip%3A3.696--2' :
        'biocontainers/phylip:v1-3.697dfsg-1-deb_cv1' }"
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
