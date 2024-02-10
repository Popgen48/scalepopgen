process SELSCAN_NORM{

    tag { "${method}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/selscan:1.2.0a--h0fdf51a_4' :
        'biocontainers/selscan:1.2.0a--h0fdf51a_5' }"
    publishDir("${params.outdir}/selection/selscan/${method}/normalized/${local_dir}/", mode:"copy")

    input:
        tuple val(meta), path(out_files)
        val(method)

    output:
        tuple val(meta), path ("*norm*"), emit: txt

    script:
        
        local_dir = meta.id
        def args = task.ext.args ?: ''
        args1 = method == "ihs" ? " --ihs ": " --xpehh "
       


        """
        norm ${args1} --files ${out_files} ${args}

        """ 
        
        
}
