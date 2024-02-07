process PYTHON_COLLECT_SELECTION_RESULTS{

    tag { "${pop}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/prepare_manhattan_input:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/selection/vcftools/${method}/${pop}/genomewide/", mode:"copy")

    input:
        tuple val(pop), path(results)
        val(method)

    output:
        tuple val(meta), path("${pop_n}_${method}.out"), emit: txt
        tuple val(meta), path("${pop_n}_${method}.cutoff"), emit: cutoff
        
    
    script:
        pop_n = (method == "sweepfinder2" || method == "ihs") ? pop.id: pop
        window_size = params.window_size
        perc_threshold = params.perc_threshold
        outfile = pop_n+"_"+method
        meta = [:]
        meta.id = pop_n+"_"+method

        """
        
        python3 ${baseDir}/bin/create_manhattanplot_input.py ${window_size} ${perc_threshold} ${method} ${outfile} ${results}
        
        
        """ 

}
