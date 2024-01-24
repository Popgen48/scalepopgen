process VCFTOOLS_KEEP{

    tag { "keep_indi_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    publishDir("${params.outdir}/${local_dir}/", mode:"copy")

    input:
        tuple val(meta), file(f_vcf), file(idx), file(f_map), file(unrel_id)
        val(analysis)

    output:
        tuple val(meta), file("${output_v}"), emit:vcf
        path("*final_kept_indi_list.txt"), emit:final_keep_list optional true
        path("*.log")
    
    script:
        chrom = meta.id
        output_v = analysis == "keep" ? params.outprefix+"_filt_samples.vcf.gz" : chrom+"_"+unrel_id.getName().minus(".txt")+".vcf.gz"
        local_dir = analysis == "keep" ? "indi_filtered": "selscan/prepare_input"
        outprefix = params.outprefix
                
            """

            vcftools --gzvcf ${f_vcf} --keep ${unrel_id} --recode --stdout |sed "s/\\s\\.:/\t.\\/.:/g"|gzip -c > ${output_v}

            cp .command.log ${chrom}_filt_samples.log

            #if [[ "${analysis}" == "keep" ]];then;cat ${unrel_id} > ${outprefix}_final_kept_indi_list.txt;fi


            """        
            
        
}
