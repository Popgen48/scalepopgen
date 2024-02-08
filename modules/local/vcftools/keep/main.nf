process VCFTOOLS_KEEP{

    tag { "keep_indi_${chrom}" }
    label "process_medium"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/${local_dir}/vcftools/keep/", mode:"copy")

    input:
        tuple val(meta), file(f_vcf), file(idx), file(f_map), file(unrel_id)
        val(analysis)

    output:
        tuple val(meta), file("${output_v}"), emit:vcf
        path("*final_kept_indi_list.txt"), emit:final_keep_list optional true
        path("*.log")
        path "versions.yml", emit: versions
    
    script:
        chrom = meta.id
        output_v = analysis == "keep" ? chrom+"_filt_samples.vcf.gz" : chrom+"_"+unrel_id.getName().minus(".txt")+".vcf.gz"
        local_dir = analysis == "keep" ? "sample_filtering": "selection/selscan/prepare_input"
        outprefix = params.outprefix
                
            """

    vcftools --gzvcf ${f_vcf} --keep ${unrel_id} --recode --stdout | bgzip -c > ${output_v}

    cp .command.log ${chrom}_filt_samples.log

    #if [[ "${analysis}" == "keep" ]];then;cat ${unrel_id} > ${outprefix}_final_kept_indi_list.txt;fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


            """        
            
        
}
