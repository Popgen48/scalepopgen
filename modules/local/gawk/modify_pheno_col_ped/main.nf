process GAWK_MODIFY_PHENO_COL_PED{

    tag { "preparing_new_map" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/smartpca/input/", mode:"copy")

    input:
        tuple val(meta), path(pedmap)
    output:
        tuple val(meta), path("*.1.ped"), emit: ped
        
    
    script:
        outprefix = params.outprefix
        prefix = meta.id


        """
        awk '\$6=\$1' ${prefix}.ped > ${prefix}.1.ped

        """ 

            
}
