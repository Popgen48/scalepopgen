process PYTHON_PLOT_SAMPLE_STATS{

    tag { "${outprefix}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/plot_admixture:1.0.0' :
        'popgen48/plot_admixture:1.0.0' }"
    publishDir("${params.outdir}/summary_stats/samples/", mode:"copy")

    input:
	path(sample_summary)
        path(fam)
        val(is_vcf)

    output:
    	path("*.html")

    when:
     	task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix
        b_is_vcf = is_vcf ? "vcf":"plink"
        
        
        
        """

	python3 ${baseDir}/bin/plot_sample_snp_statistics.py ${sample_summary} ${baseDir}/extra/plots/sample_summary_stats.yml ${fam} ${b_is_vcf} ${outprefix}_samplewise_snp_counts

	""" 
        

}
