process PLINK2_SAMPLE_COUNTS{

    tag { "calculating_chromosomewise_summary_${chrom}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    publishDir("${params.outdir}/summary_stats/samples/", mode:"copy")

    input:
        tuple val(meta), path(variants)
        val(is_vcf)

    output:
        path("${chrom}_sample_summary.scount"), emit: samplesummary
        path "versions.yml", emit: versions
        
    
    script:
        chrom = meta.id
        def opt_args = ""
        opt_args = opt_args + " --chr-set "+ params.max_chrom+" --threads "+task.cpus
        if(is_vcf){
            opt_args = opt_args+" --vcf "+variants
        }
        else{
            opt_args = opt_args + " --bfile "+meta.id
        }
	if( params.allow_extra_chrom ){
                
            opt_args = opt_args + " --allow-extra-chr "

            }
        opt_args = opt_args + " --nonfounders --sample-counts --out "+chrom+"_sample_summary"

        """
        
    plink2 ${opt_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS


        """ 
}
