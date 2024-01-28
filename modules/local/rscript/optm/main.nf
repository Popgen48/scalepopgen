process RSCRIPT_OPTM{

    tag { "estimate_optimal_mig_edge" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/rscript_optm:0.1.6' :
        'popgen48/rscript_optm:0.1.6' }"
    publishDir("${params.outdir}/treemix", mode:"copy")

    input:
        path(llik)
	path(modelcov)
	path(cov)

    output:
        path("OptM_results*")

    when:
     task.ext.when == null || task.ext.when
    
   
    script:
        

        """
	    Rscript ${baseDir}/bin/est_opt_mig_edge.r -d `pwd` > OptM_results.log 2>&1

        """ 
}
