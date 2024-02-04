process RSCRIPT_PLOT_TREE{

    tag { "treemix_tree" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/rscript_treemix:1.0.0' :
        'popgen48/rscript_treemix:1.0.0' }"
    publishDir("${params.outdir}/treemix/rscript/plot_tree/", mode:"copy")

    input:
        path(treeout)
        path(vertices)
        path(edges)
        path(covse)
        val(method)

    output:
	tuple val(n_mig), path("*.pdf"), emit: pdf

    when:
        task.ext.when == null || task.ext.when

    script:
        prefix = treeout.getName().minus(".treeout.gz")
        n_mig = method=="add_mig"? prefix.split("\\.")[-1]:prefix

        """
	Rscript ${baseDir}/bin/plot_tree.r ${prefix} ${prefix}.pdf

        """ 

}
