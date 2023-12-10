process VCFTOOLS_REMOVE{

    tag { "remove_indi_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    publishDir("${params.outdir}/vcftools/indi_filtered/", mode:"copy")

    input:
        tuple val(meta), path(f_vcf), path(rem_indi)

    output:
        tuple val(meta), path("${chrom}_filt_samples.vcf.gz"), emit:f_meta_vcf
        path("*.log")
    
    script:
            chrom = meta.id
                
            """
            awk '{print \$2}' ${rem_indi} > remove_indi_list.txt
            
            vcftools --gzvcf ${f_vcf} --remove remove_indi_list.txt --recode --stdout |sed "s/\\s\\.:/\t.\\/.:/g"|gzip -c > ${chrom}_filt_samples.vcf.gz

            cp .command.log ${chrom}_filt_samples.log



            """        
            
}
