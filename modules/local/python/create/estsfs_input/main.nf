process PYTHON_CREATE_ESTSFS_INPUT{

    tag { "${chrom}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py310h41dec4a_0':
        'quay.io/biocontainers/pysam:0.22.0--py310h41dec4a_0' }"
    publishDir("${params.outdir}/selection/est-sfs/", mode:"copy")

    input:
        tuple val(meta), path(vcf), path(idx), path(sample_map)

    output:
        tuple val(meta), path("*_config.txt"), emit:config
        tuple val(meta), path("*_data.txt"), emit:data
        tuple val(meta), path("*_non_missing_sites.map"), emit:map
        tuple val(meta), path("*_seed.txt"), emit:seed
    
    script:

        def outgroup = params.outgroup
        chrom = meta.id

        """
        
        python3 ${baseDir}/bin/create_estsfs_inputs.py -c ${chrom} -V ${vcf} -M ${sample_map} -o ${outgroup}

        """ 
}
