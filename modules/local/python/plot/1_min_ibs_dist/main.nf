process PYTHON_PLOT_1_MIN_IBS_DIST{

    tag { "plot_1_min_ibs_distance" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_ibs:1.0.0' :
        'popgen48/plot_ibs:1.0.0' }"
    publishDir("${params.outdir}/genetic_structure/interactive_plots/1_min_ibs_dist/", mode:"copy")

    input:
        path(mdist)
        path(id)
        path(pop_sc_color)
        path(nj_yml)

    output:
        path("*_mqc.html"), emit: html
        path("*.svg")
        path("polyphyletic_pop_list.txt")
        path("*.ibs.dist")
        path("*.tree")
        path("*.log")
        path("*_monophyletic_subtrees.txt"), emit: popsubtree optional true


    when:
        task.ext.when == null || task.ext.when

    script:
        outgroup = params.outgroup
        prefix = params.outprefix
	
        """
        if grep -qw ${outgroup} ${id};then  
            python3 ${baseDir}/bin/make_ibs_dist_nj_tree.py -r ${outgroup} -i ${mdist} -m ${id} -c ${pop_sc_color} -y ${nj_yml} -o ${prefix}
        else
            python3 ${baseDir}/bin/make_ibs_dist_nj_tree.py -i ${mdist} -m ${id} -c ${pop_sc_color} -y ${nj_yml} -o ${prefix}
        fi

        cat ${baseDir}/assets/ibs_comments.txt *.html > ${prefix}_ibs_mqc.html

        cp .command.log calc_1_mins_ibs_dist.log

        """ 

}
