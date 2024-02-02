process GAWK_MODIFY_PHENO_COL_PED{

    tag { "preparing_new_map" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/pca/gawk/modify_pheno_col_ped/", mode:"copy")

    input:
        tuple val(meta), path(pedmap)
    output:
        tuple val(meta), path("*.1.ped"), emit: ped
         path "versions.yml", emit: versions
       
    
    script:
        outprefix = params.outprefix
        prefix = meta.id


        """
    awk '\$6=\$1' ${prefix}.ped > ${prefix}.1.ped

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 

            
}
