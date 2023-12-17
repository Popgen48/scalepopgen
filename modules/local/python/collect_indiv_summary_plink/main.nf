process PYTHON_COLLECT_INDIV_SUMMARY_PLINK{

    tag { "combining_indiv_summary" }
    label "process_single"
    conda 'conda-forge::python=3.10'
    container "python:3.10-alpine"
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
