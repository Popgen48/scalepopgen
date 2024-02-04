process TREEMIX{

    tag { "${n_iter}_${n_mig}_${n_seed}" }
    label "process_high"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/treemix:1.13' :
        'popgen48/treemix:1.13' }"
    publishDir("${params.outdir}/treemix/treemix/${local_dir}/", mode:"copy")

    input:
        tuple path(treemix_in), val(n_seed), val(n_mig), val(n_iter)
        val(method)

    output:
        path("*.vertices.gz"), emit: vertices
	path("*.llik"), emit:llik
	path("*.treeout.gz"), emit: treeout
	path("*.edges.gz"), emit: edges
	path("*.modelcov.gz"), emit: modelcov
	path("*.covse.gz"), emit: covse
	path("*.cov.gz"), emit: cov

    when:
     task.ext.when == null || task.ext.when

    script:
        def args1 = params.outgroup ? " -root "+params.outgroup:''
        def args2 = (method == "bootstrap" || method == "add_mig") ? (params.set_random_seed == true ? " --seed "+n_seed : '') : ''
        def args3 = (method == "bootstrap" || method == "add_mig") ? (method == "bootstrap" ? " -bootstrap ": " -global -m "+n_mig):''
        def outprefix = (method == "bootstrap" || method == "default") ? params.outprefix + "_"+n_seed : params.outprefix +"."+n_iter+"."+n_mig
        def k_snps = method == "add_mig" ? (params.rand_k_snps ? n_seed:params.k_snps): params.k_snps
        local_dir =  method == "add_mig" ? "mig_"+n_mig: "mig_0"

        """
        treemix -i ${treemix_in} -k ${k_snps} -o ${outprefix} ${args1} ${args2} ${args3}

        """ 

}
