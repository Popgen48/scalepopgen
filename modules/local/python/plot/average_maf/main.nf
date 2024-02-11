process PYTHON_PLOT_AVERAGE_MAF{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_maf:1.0.0' :
        'popgen48/plot_maf:1.0.0' }"
    publishDir("${params.outdir}/summary_stats/python/plot/average_maf/", mode:"copy")

    input:
        path(bim)
        path(color_file)
	path(mafsummary)

    output:
    	path("${outprefix}_maf_summary_mqc.html"), emit: maf_stats_html
    	path("populationwise_maf_report.txt")

    when:
     	task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix
        window_size = params.window_size
        
        
        
        """

	python3 ${baseDir}/bin/plot_average_maf.py ${bim} ${window_size} ${color_file} ${mafsummary}

        cat ${baseDir}/assets/maf_comments.txt maf_summary.html > ${outprefix}_maf_summary_mqc.html

	""" 
        

}
