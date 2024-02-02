process PLINK_CALC_MAF{

    tag { "${chrom}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'biocontainers/plink:1.90b6.21--h779adbc_1' }"
    publishDir("${params.outdir}/summary_stats/plink/calc_maf_hardy/", mode:"copy")

    input:
        tuple val(meta), path(bed_f)
        path(cluster_file)
        val(method)

    output:
        path("*.frq.strat"), emit: mafsummary, optional: true
        path("*.hwe"), emit: hwesummary, optional: true 
        //path "versions.yml", emit: versions
        
    
    script:
        chrom = meta.id
        def opt_args = ""
        opt_args = opt_args + " --chr-set "+ params.max_chrom+" --threads "+task.cpus
        opt_args = opt_args + " --bfile "+meta.id
	if( params.allow_extra_chrom ){
                
            opt_args = opt_args + " --allow-extra-chr "

            }
        
        if(method == "freq"){

            opt_args = opt_args + " --nonfounders --freq --within "+cluster_file+" --out "+chrom
        
            }
        
        else{

            opt_args = opt_args + " --nonfounders --hardy --keep "+cluster_file+" --out "+cluster_file.getName().minus(".txt")

            }

        """
        
        plink ${opt_args}



        """ 
}
