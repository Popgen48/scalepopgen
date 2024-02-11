process PYTHON_PLOT_AVERAGE_HET{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_maf:1.0.0' :
        'popgen48/plot_maf:1.0.0' }"
    publishDir("${params.outdir}/summary_stats/python/plot/average_het/", mode:"copy")

    input:
        path(bim)
        path(color_file)
	path(hwe_files)

    output:
    	path("${outprefix}_obs_het_mqc.html"), emit: obs_het_html
    	path("${outprefix}_exp_het_mqc.html"), emit: exp_het_html
        path("populationwise_heterozygosity_report.txt")

    when:
     	task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix
        window_size = params.window_size
        
        
        
        """

	python3 ${baseDir}/bin/plot_average_het.py ${bim} ${window_size} ${color_file} ${hwe_files}

        cat ${baseDir}/assets/obs_het_comments.txt obs_het.html > ${outprefix}_obs_het_mqc.html

        cat ${baseDir}/assets/exp_het_comments.txt exp_het.html > ${outprefix}_exp_het_mqc.html

	""" 
        

}
