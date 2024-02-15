process PLINK2_FILTER_SAMPLES{

    tag { "filter_indi_${new_prefix}" }
    label "process_single"
    conda "bioconda::plink2==2.00a3.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'quay.io/biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    publishDir("${params.outdir}/sample_filtering/plink2/filter_samples/", mode:"copy")

    input:
        tuple val(meta), path(vcf)
        val(is_vcf_v)
        path(rem_indi)
        

    output:
        path("*miss"), emit: missing_indi_report optional true
        path("*.log" ), emit: log_file
        path("*king*"), emit: king_out optional true
        path("*.mindrem.id"), emit: rem_indi optional true
        tuple val(n_meta), path("${new_prefix}_rem_indi.{bed,bim,fam}"), emit: bed
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        new_prefix = meta.id
        n_meta = [:]
        n_meta.id = new_prefix+"_rem_indi"
        is_vcf = is_vcf_v ? "vcf": "bed"
        def opt_args = ""
        opt_args = opt_args + " --chr-set "+ params.max_chrom+" --threads "+task.cpus
        if( is_vcf == "vcf" ){
            opt_args = opt_args + " --vcf "+vcf 
        }
        if( is_vcf == "bed" ){
            opt_args = opt_args + " --bfile "+new_prefix
        }
        if ( params.mind > 0 ){        
            opt_args = opt_args + " --mind "+ params.mind
        }
        if ( params.allow_extra_chrom ){        
            opt_args = opt_args + " --allow-extra-chr "
        }
        opt_args = opt_args + " --make-bed --out "+new_prefix+"_rem_indi"
        if ( params.rem_indi ){
            opt_args = opt_args + " --remove "+rem_indi
        }
        if ( params.king_cutoff > 0 ){
            opt_args = opt_args + " --king-cutoff " + params.king_cutoff 
        }
    
        """
    plink2 ${opt_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS

        """ 

}
