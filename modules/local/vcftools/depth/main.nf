process VCFTOOLS_DEPTH{

    tag { "keep_indi_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
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
