process VCFTOOLS_KEEP{

    tag { "keep_indi_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    publishDir("${params.outdir}/vcftools/indi_filtered/", mode:"copy")

    input:
        tuple val(meta), file(f_vcf), file(idx), file(f_map), file(unrel_id)

    output:
        tuple val(meta), file("${chrom}_filt_samples.vcf.gz"), emit:vcf
        path("*final_kept_indi_list.txt"), emit:final_keep_list
        path("*.log")
    
    script:
        outprefix = params.outprefix
        chrom = meta.id
                
            """

            vcftools --gzvcf ${f_vcf} --keep ${unrel_id} --recode --stdout |sed "s/\\s\\.:/\t.\\/.:/g"|gzip -c > ${chrom}_filt_samples.vcf.gz

            cp .command.log ${chrom}_filt_samples.log

            cat ${unrel_id} > ${outprefix}_final_kept_indi_list.txt


            """        
            
        
}
