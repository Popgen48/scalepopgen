process VCFTOOLS_FILTER_SITES{

    tag { "filter_sites_${chrom}" }
    label "process_medium"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/snp_filtering/vcftools/sites_filtes/", mode:"copy")

    input:
        tuple val(meta), path(f_vcf), path(f_rem_snp)

    output:
        tuple val(meta), path("*filt_sites.vcf.gz"), emit: vcf
        path("*.log"), emit: log
        path "versions.yml", emit: versions
    
    script:
        def opt_arg = ""
        chrom = meta.id
        prefix = chrom
        if(params.maf >= 0){
            opt_arg = opt_arg + " --maf "+params.maf
        }
        if(params.min_meanDP >= 0){
            opt_arg = opt_arg + " --min-meanDP "+params.min_meanDP
        }
        if(params.max_meanDP >= 0){
            opt_arg = opt_arg + " --max-meanDP "+params.max_meanDP
        }
        if(params.hwe >= 0){
            opt_arg = opt_arg + " --hwe "+params.hwe
        }
        if(params.max_missing >= 0){
            opt_arg = opt_arg + " --max-missing "+params.max_missing
        }
        if(params.minQ >= 0){
            opt_arg = opt_arg + " --minQ "+params.minQ
        }
        if(params.custom_snps){
            if(params.custom_snps_process == "exclude"){
                opt_arg = opt_arg + " --exclude-positions "+ f_rem_snp
            }
            else{
                opt_arg = opt_arg + " --positions "+ f_rem_snp
            }
        }

        """
        
    vcftools --gzvcf ${f_vcf} ${opt_arg} --recode --stdout |bgzip -c > ${prefix}_filt_sites.vcf.gz


    cp .command.log ${prefix}_filter_sites.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS

        """ 
}
