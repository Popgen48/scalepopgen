process RSCRIPT_PLOT_TREE{

    tag { "treemix_tree" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/rscript_treemix:1.0.0' :
        'popgen48/rscript_treemix:1.0.0' }"
    publishDir("${params.outdir}/treemix/treemix/${local_dir}/", mode:"copy")

    input:
        path(treeout)
        path(vertices)
        path(edges)
        path(covse)
        val(method)

    output:
	path("*.pdf"), emit: pdf

    when:
     task.ext.when == null || task.ext.when

    script:
        prefix = treeout.getName().minus(".treeout.gz")
        local_dir =  method == "add_mig" ? "mig_"+n_mig: "mig_0"

        """
	Rscript ${baseDir}/bin/plot_tree.r ${prefix} ${prefix}.pdf

        """ 

}
