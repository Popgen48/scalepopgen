process VCFTOOLS_REMOVE{

    tag { "remove_indi_${chrom}" }
    label "process_medium"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/sample_filtering/vcftools/remove/", mode:"copy")

    input:
        tuple val(meta), path(f_vcf), path(idx), path(rem_indi)

    output:
        tuple val(meta), path("${chrom}_filt_samples.vcf.gz"), emit:vcf
        path("*.log")
        path "versions.yml", emit: versions
    
    script:
            chrom = meta.id
                
            """
            
    vcftools --gzvcf ${f_vcf} --remove ${rem_indi} --recode --stdout |bgzip -c > ${chrom}_filt_samples.vcf.gz

    cp .command.log ${chrom}_filt_samples.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


            """        
            
}
