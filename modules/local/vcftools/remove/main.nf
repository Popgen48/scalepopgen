process VCFTOOLS_REMOVE{

    tag { "remove_indi_${chrom}" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    publishDir("${params.outdir}/vcftools/indi_filtered/", mode:"copy")

    input:
        tuple val(meta), path(f_vcf), path(idx), path(rem_indi)

    output:
        tuple val(meta), path("${chrom}_filt_samples.vcf.gz"), emit:f_meta_vcf
        path("*.log")
        path "versions.yml", emit: versions
    
    script:
            chrom = meta.id
                
            """
            
    vcftools --gzvcf ${f_vcf} --remove ${rem_indi} --recode --stdout |sed "s/\\s\\.:/\t.\\/.:/g"|gzip -c > ${chrom}_filt_samples.vcf.gz

    cp .command.log ${chrom}_filt_samples.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


            """        
            
}
