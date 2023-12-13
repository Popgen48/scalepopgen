process FILTER_SNPS{

    tag { "filter_snps_${new_prefix}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    publishDir("${params.outdir}/plink2/snps_filtered/", mode:"copy")

    input:
        tuple val(meta), file(bed)

    output:
        tuple val(n_meta), path("${new_prefix}_filt_site*.{bed,bim,fam}"), emit: n1_meta_bed
        path("*.log" ), emit: log_file

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

        if ( params.rem_snps ){
        
            opt_args = opt_args + " --exclude " + params.rem_snps
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
            

        """ 
}
