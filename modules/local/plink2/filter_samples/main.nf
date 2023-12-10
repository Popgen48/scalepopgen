process FILTER_SAMPLES{

    tag { "filter_indi_${new_prefix}" }
    label "process_single"
    conda "bioconda::plink2=2.00a2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a2.3--h712d239_1' :
        'biocontainers/plink2:2.00a2.3--h712d239_1' }"

    publishDir("${params.outdir}/plink/indi_filtered/", mode:"copy")

    input:
        tuple val(meta), path(vcf)
        val(is_vcf_v)
        

    output:
        path("*miss"), emit: missing_indi_report optional true
        path("indi_kept.txt"), emit: keep_indi_list
        path("*.log" ), emit: log_file
        path("*king*"), emit: king_out optional true
        tuple val(n_meta), path("${new_prefix}_rem_indi.{bed,bim,fam}"), emit: n1_meta_bed optional true

    when:
        task.ext.when == null || task.ext.when

    script:
        new_prefix = meta.id
        n_meta = [:]
        n_meta.id = new_prefix+"_rem_indi"
        is_vcf = is_vcf_v ? "vcf": "bed"
        def opt_args = ""
        opt_args = opt_args + " --chr-set "+ params.max_chrom+" --threads "+task.cpus
        def rem_indi = params.rem_indi
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
        if ( params.king_cutoff > 0 ){
        
            opt_args = opt_args + " --king-cutoff " + params.king_cutoff 

        
        
            """
            
            if [ ${rem_indi} == "null"  ]
                then
                    plink2 ${opt_args}
            else
                if [ ${is_vcf} == "vcf" ]
                    then
                        awk '{print \$2}' ${rem_indi} > custom_indi_rem_list.txt
                else
                    cat ${rem_indi} > custom_indi_rem_list.txt
                fi
                plink2 ${opt_args} --remove custom_indi_rem_list.txt
            fi
            
            mv ${new_prefix}_rem_indi.king.cutoff.in.id indi_kept.txt

            """ 
        }
        else{
        
            """
            
            if [ ${rem_indi} == "null"  ]
                then
                    plink2 ${opt_args}
            else
                if [ ${is_vcf} == "vcf" ]
                    then
                        awk '{print \$2}' ${rem_indi} > custom_indi_rem_list.txt
                else
                    cat ${rem_indi} > custom_indi_rem_list.txt
                fi
                plink2 ${opt_args} --remove custom_indi_rem_list.txt
            fi

            awk '{print \$2}' ${new_prefix}_rem_indi.fam > indi_kept.txt
                

            """ 

        }
}
