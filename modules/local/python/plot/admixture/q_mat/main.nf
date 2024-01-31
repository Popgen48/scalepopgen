process PYTHON_PLOT_ADMIXTURE_Q_MAT{

    tag { "estimating_bestK" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_admixture:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/genetic_structure/interactive_plots/", mode:"copy")

    input:
	path(q_files)
        path(fam_file)
        path(admixture_colors)
        path(plot_yml)
        path(pop_order)

    output:
    	path("*_mqc.html"), emit: qmat_html

    when:
     	task.ext.when == null || task.ext.when

    script:

        args = task.ext.args ?: ''
        def outprefix = params.outprefix
        args = pop_order != [] ? "-s "+pop_order : ''
        
        
        
        """
        ls *.Q > q_files.txt

	python3 ${baseDir}/bin/plot_interactive_q_mat.py -q q_files.txt -f ${fam_file} -y ${plot_yml} -c ${admixture_colors} -o ${outprefix} ${args}

        cat ${baseDir}/assets/admixture_comments.txt *.html > ${outprefix}_qmats_mqc.html

	""" 
        

}
