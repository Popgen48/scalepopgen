process PYTHON_COLLECT_VCFTOOLS_SELECTION_RESULTS{

    tag { "${pop}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "popgen48/prepare_manhattan_input:1.0.0"
    publishDir("${params.outdir}/summary_stats/samples/", mode:"copy")

    input:
        tuple val(pop), path(result_files)
        val(method)

    output:
        tuple val(meta), path("${pop}_${method}.out"), emit: txt
        tuple val(meta), path("${pop}_${method}.cutoff"), emit: cutoff
        
    
    script:
        window_size = params.window_size
        per_threshold = params.perc_threshold
        outfile = pop+"_"+method
        meta = [:]
        meta.id = pop+"_"+method

        """
        
        python3 ${baseDir}/bin/create_manhattanplot_input.py ${window_size} ${per_threshold} ${method} ${outfile} ${result_files}
        
        
        """ 

}
