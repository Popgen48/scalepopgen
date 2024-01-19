process GAWK_MERGE_FREQ_FILES{

    tag { "${pop}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/sweepfinder2/input_files/", mode:"copy")

    input:
        tuple val(meta), path( freqs )

    output:
        tuple val(meta), path ( "*_combined.freq"), emit: pop_cfreq

    script:
        pop = meta.id    

        """
                        
        awk '{print}' ${freqs} > ${pop}_combined.freq
            

        """ 
}
