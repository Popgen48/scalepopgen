process GAWK_MAKE_CLUSTER_FILE{

    tag { "making_cluster_file" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/genetic_structure/fst/", mode:"copy")

    input:
        path(fam)
        

    output:
        path("*.cluster"), emit:txt
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        
        outprefix = params.outprefix
	
        """

    awk '{print \$1,\$2,\$1}' ${fam} > ${outprefix}.cluster

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 

}
