process PYTHON_PLOT_ADMIXTURE_Q_MAT{

    tag { "estimating_bestK" }
    label "oneCpu"
    conda "${moduleDir}/environment.yml"
    container "popgen48/plot_admixture:1.0.0"
    publishDir("${params.outDir}/genetic_structure/admixture/", mode:"copy")

    input:
	path(q_files)
        path(fam_file)
        path(admixture_colors)
        path(plot_yml)
        path(pop_order)

    output:
    	path("*.html")

    when:
     	task.ext.when == null || task.ext.when

    script:

        args = task.ext.args ?: ''
        def outprefix = params.outprefix
        args = pop_order != [] ? "-s "+pop_order : ''
        
        
        
        """
        ls *.Q > q_files.txt

	python3 ${baseDir}/bin/plot_interactive_q_mat.py -q q_files.txt -f ${fam_file} -y ${plot_yml} -c ${admixture_colors} -o ${outprefix} ${args}

	""" 
        

}
