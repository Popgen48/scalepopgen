process PYTHON_PLOT_PAIRWISE_FST{

    tag { "plot_pairwise_fst_${new_prefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_fst:1.0.0' :
        'popgen48/plot_fst:1.0.0' }"
    publishDir("${params.outdir}/genetic_structure/interactive_plots/fst/", mode:"copy")

    input:
        path(pairwise_fst)
        path(color_map)
        path(nj_yml)
        

    output:
        path("*.tree")
        path("*.dist")
        path("*_mqc.html"), emit:html
        path("*.svg")

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        prefix = params.outprefix
        outgroup = params.outgroup
	
        """


        if grep -qw ${outgroup} ${pairwise_fst};then  
            python3 ${baseDir}/bin/make_fst_dist_nj_tree.py -i ${pairwise_fst} -r ${outgroup} -o ${prefix} -y ${nj_yml} -c ${color_map}
        else
            python3 ${baseDir}/bin/make_fst_dist_nj_tree.py -i ${pairwise_fst} -o ${prefix} -y ${nj_yml} -c ${color_map}
        fi
        
        cat ${baseDir}/assets/fst_comments.txt *.html > ${prefix}_fst_mqc.html

        """ 

}
