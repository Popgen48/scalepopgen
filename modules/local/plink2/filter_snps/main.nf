process FILTER_SNPS{

    tag { "filter_snps_${new_prefix}" }
    label "process_single"
    conda "bioconda::plink2==2.00a3.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'quay.io/biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    publishDir("${params.outdir}/snp_filtering/plink2/filter_snps/", mode:"copy")

    input:
        tuple val(meta), file(bed)
        path(rem_snps)

    output:
        tuple val(n_meta), path("${new_prefix}_filt_site*.{bed,bim,fam}"), emit: n1_meta_bed
        path("*.log" ), emit: log_file
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        new_prefix = meta.id 
        n_meta = [:]
        n_meta.id = meta.id+"_filt_sites"
        def opt_args = ""
        opt_args = opt_args + " --chr-set "+ params.max_chrom
	if( params.allow_extra_chrom ){
                
            opt_args = opt_args + " --allow-extra-chr "

            }

        if ( rem_snps != [] ){
        
            opt_args = opt_args + " --" +params.custom_snps_process+" "+ rem_snps
        }
        
        if ( params.max_missing > 0 ){
        
            opt_args = opt_args + " --geno " + params.max_missing
        }

        if ( params.hwe > 0 ){
        
            opt_args = opt_args + " --hwe " + params.hwe
        }

        if ( params.maf > 0 ){
        
            opt_args = opt_args + " --maf " + params.maf
        }

        opt_args = opt_args + " --make-bed --out " + new_prefix +"_filt_sites"
        
        """
	
    plink2 --bfile ${new_prefix} ${opt_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
            

        """ 
}
