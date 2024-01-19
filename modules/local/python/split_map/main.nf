process PYTHON_SPLIT_MAP{

    tag { "${tool}" }
    label "process_single"
    conda 'conda-forge::python=3.10'
    container "python:3.10-alpine"
    publishDir("${params.outdir}/selection/input_pop/${tool}", mode:"copy")

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
