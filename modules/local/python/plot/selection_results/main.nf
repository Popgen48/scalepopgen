process PYTHON_PLOT_SELECTION_RESULTS{

    tag { "${outprefix}" }
    label "oneCpu"
    container "popgen48/plot_selection_results:1.0.0"
    conda "${moduleDir}/environment.yml"
    publishDir("${params.outdir}/vcftools/selection/${method}/", mode:"copy")

    input:
        tuple val(meta), path(merged_result), val(cutoff), path(yml)
        val(method)
        

    output:
        tuple val(meta), path("*.html")

    script:
        window_size = params.window_size
        outprefix = meta.id

        """
        
        python ${baseDir}/bin/plot_selection_results.py ${merged_result} ${yml} ${cutoff} ${window_size} ${method} ${outprefix}.html
        

        """ 
}
