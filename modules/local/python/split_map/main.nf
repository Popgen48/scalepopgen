process PYTHON_SPLIT_MAP{

    tag { "${tool}" }
    label "process_single"
    conda 'conda-forge::python=3.10'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/python_bash:3.10-alpine' :
        'popgen48/python_bash:3.10-alpine' }"
    publishDir("${params.outdir}/selection/vcftools/input_pop/${tool}", mode:"copy")

    input:
        path(sample_map)
        val(tool)

    output:
        path ("*.txt"), emit: poptxt
        path ( "*included_samples.csv" ), emit: include_samples

    script:
    
        def args = task.ext.args ?: ''

        """

        python ${baseDir}/bin/split_sample_map.py -m ${sample_map} ${args} -t ${tool}

        """ 
}
