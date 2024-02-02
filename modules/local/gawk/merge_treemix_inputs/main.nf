process GAWK_MERGE_TREEMIX_INPUTS{

    tag { "merging_treemix_inputs" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/treemix/input_files/", mode:"copy")

    input:
        path(treemix_inputs)

    output:
        path("*treemix_input.gz"), emit: gz
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix

        """

    cat ${treemix_inputs} | awk '{if(NR==1){print;next}else;if(\$0~/,/){print}}'|gzip -c > ${outprefix}_treemix_input.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 
}
