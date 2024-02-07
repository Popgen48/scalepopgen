process PYTHON_PLOT_SELECTION_RESULTS{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_selection_results:1.0.0' :
        'popgen48/plot_selection_results:1.0.0' }"
    publishDir("${params.outdir}/selection/python/plot/${method}/", mode:"copy")

    input:
        tuple val(meta), val(cutoff), path(merged_result), path(yml)
        val(method)
        

    output:
        tuple val(meta), path("*.html"), emit: html

    script:
        window_size = method == "LR" ? 1:params.window_size
        outprefix = merged_result.getName().minus(".out")

        """
        
        python ${baseDir}/bin/plot_selection_results.py ${merged_result} ${yml} ${cutoff} ${window_size} ${method} ${outprefix}
        

        """ 
}
