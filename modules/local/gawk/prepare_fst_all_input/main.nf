process GAWK_PREPARE_FST_ALL_INPUT{

    tag { "${pop1}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    

    input:
        tuple path(map), path(pop_file)
        

    output:
        tuple val(pop1), path("excl_${pop1}.txt"), emit:txt
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        
        pop1 = pop_file.getName().minus(".txt")
	
        """

    awk 'NR==FNR{sample[\$1];next}!(\$1 in sample){print \$1}' ${pop_file} ${map} > excl_${pop1}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 

}
