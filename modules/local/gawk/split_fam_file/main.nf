process GAWK_SPLIT_FAM_FILE{

    tag { "split_fam" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/gawk/split_fam_file/", mode:"copy")

    input:
        path(fam)
        

    output:
        path("*_id.txt"), emit:txt
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        
	
        """

    awk '{print \$1,\$2 >> \$1"_id.txt"}' ${fam} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 

}
