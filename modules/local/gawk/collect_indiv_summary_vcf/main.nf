process GAWK_COLLECT_INDIV_SUMMARY_VCF{

    tag { "combining_indiv_summary" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/summary_stats/indiv_stats/", mode:"copy")

    input:
        path(depthreports)
        path(indivreports)

    output:
        path("genomewide_sample_stats.tsv")
        
    
    script:
        outprefix = params.outprefix

        """
        
        cat ${depthreports} > ${outprefix}_chrm_depth_reports.txt

        awk 'BEGIN{OFS="\t"}\$0!~/INDV/{depth_s = \$3*\$2;count_s = \$2;if(!(\$1 in snp_count)){snp_count[\$1]=count_s;depth_count[\$1]=depth_s;next}else{snp_count[\$1]+=count_s;depth_count[\$1]+=depth_s}}END{for(sample in snp_count){print sample, snp_count[sample], depth_count[sample]/snp_count[sample]}}' ${outprefix}_chrm_depth_reports.txt > sample_depth.tsv

        awk 'BEGIN{OFS="\t"}NR==FNR{sample_depth[\$1]=\$3;next}{if(FNR==1){print \$1,\$2,\$3,\$4,\$5,\$6,\$7,"AVE_DEPTH";next}else;print \$1,\$2,\$3,\$4,\$5,\$6,\$7,sample_depth[\$1]}' sample_depth.tsv ${indivreports} > genomewide_sample_stats.tsv
        
        """ 

}
