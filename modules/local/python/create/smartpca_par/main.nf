process PYTHON_CREATE_SMARTPCA_PAR{

    tag { "create smartpca par" }
    label "process_single"
    conda 'conda-forge::python=3.10'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/python_bash:3.10-alpine' :
        'popgen48/python_bash:3.10-alpine' }"
    publishDir("${params.outdir}/pca/python/create/smartpca_par", mode:"copy")

    input:
        val(meta)

    output:
        path("*.par"), emit:smartpcapar

    when:
     task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def args1 = task.ext.args1 ?:''
        prefix = meta.id
        """


	python3 ${baseDir}/bin/create_par_smartpca.py ${prefix} ${args1} ${task.cpus} ${args}



        """ 
}
