process VCFTOOLS_DEPTH{

    tag { "keep_indi_${chrom}" }
    label "process_medium"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/summary_stats/samples/", mode:"copy")

    input:
        tuple val(meta), path(f_vcf)

    output:
        path("${chrom}*.idepth"), emit: sampledepthinfo
        path("*.log")
        path "versions.yml", emit: versions
    
    script:
        
            chrom = meta.id
                
            """

    vcftools --gzvcf ${f_vcf} --depth --out ${chrom}_depth_info
           

    cp .command.log ${chrom}_depth_info.log


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS

            """        
            
        
}
