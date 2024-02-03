process PYTHON_PLOT_ADMIXTURE_CV_ERROR{

    tag { "estimating_bestK" }
    label "oneCpu"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_admixture:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/admixture/python/plot/admixture/cv_error/", mode:"copy")
    errorStrategy 'ignore'

    input:
	path(k_cv_log_files)

    output:
    	path("*_mqc.html"), emit: cv_html

    when:
     	task.ext.when == null || task.ext.when

    script:

        def args = task.ext.args ?: ''
        
        """
	python3 ${baseDir}/bin/est_best_k_and_plot.py ${args} ${k_cv_log_files}

        cat ${baseDir}/assets/cvplt_comments.txt *.html > cvplot_mqc.html

	""" 

}
