process PYTHON_COLLECT_INDIV_SUMMARY_PLINK{

    tag { "combining_indiv_summary" }
    label "process_single"
    conda 'conda-forge::python=3.10'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/python_bash:3.10-alpine' :
        'popgen48/python_bash:3.10-alpine' }"
    publishDir("${params.outdir}/summary_stats/samples/", mode:"copy")

    input:
        path(summaryfiles)
        val(is_vcf)

    output:
        path("genomewide_indiv_report.tsv"), emit: genomewidesummaryplink
        
    
    script:

        """
        
        python3 ${baseDir}/bin/combine_indiv_reports.py ${is_vcf} ${summaryfiles}
        
        
        """ 

}
