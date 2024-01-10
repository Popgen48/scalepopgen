process GAWK_MERGE_TREEMIX_INPUTS{

    tag { "merging_treemix_inputs" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/treemix/input_files/genomewide_treemix_file/", mode:"copy")

    input:
        path(treemix_inputs)

    output:
        path("*treemix_input.gz"), emit: gz

    when:
        task.ext.when == null || task.ext.when

    script:

        outprefix = params.outprefix

        """

        cat ${treemix_inputs} | awk '{if(NR==1){print;next}else;if(\$0~/,/){print}}'|gzip -c > ${outprefix}_treemix_input.gz

        """ 
}
