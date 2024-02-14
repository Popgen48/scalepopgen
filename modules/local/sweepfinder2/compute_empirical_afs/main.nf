process SWEEPFINDER2_COMPUTE_EMPIRICAL_AFS{

    tag { "${pop}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sweepfinder2:1.0--hec16e2b_4' :
        'quay.io/biocontainers/sweepfinder2:1.0--hec16e2b_4' }"
    publishDir("${params.outdir}/selection/sweepfinder2/input_files/", mode:"copy")

    input:
        tuple val(meta), path( freqs )

    output:
        tuple val(meta), path ( "*.afs" ), emit: pop_afs
        path("*.log")

    script:
        pop = meta.id    

        """
                        
        cat ${freqs} > ${pop}_combined.freq

        SweepFinder2 -f ${pop}_combined.freq ${pop}.afs

        cp .command.log sweepfinder2_compute_afs_${pop}.log

        """ 
}
