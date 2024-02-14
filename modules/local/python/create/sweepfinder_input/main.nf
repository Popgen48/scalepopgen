process PYTHON_CREATE_SWEEPFINDER_INPUT{

    tag { "${chrom}" }
    label "process_single"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py310h41dec4a_0':
        'quay.io/biocontainers/pysam:0.22.0--py310h41dec4a_0' }"
    conda "${moduleDir}/environment.yml"
    publishDir("${params.outdir}/selection/sweepfinder2/input_files/", mode:"copy")

    input:
        tuple val(meta), path( vcf ), path(pop_id), path(anc), path(recomb)
        val(method)

    output:
        tuple val(n_meta), val(chrom), path ( "${chrom}*.freq" ), emit: pop_freq
        tuple val(n_meta), val(chrom), path ( "${chrom}*recomb" ), emit: pop_recomb optional true

    script:
        def args = ""
        args1 = anc ? "-a "+ anc : ""
        args2 = method == "lr" ? ( recomb ? " -r -R "+recomb : " -r ") : ""
        chrom = meta.id
        n_meta = [:]
        pop_f = pop_id.getName().minus(".txt")
        n_meta.id = method == "lr" ? chrom+"_"+pop_f:pop_f
        args = args1 + args2+ " -o "+chrom
        
        """

        python ${baseDir}/bin/vcf_to_sweepfinder2_input.py -V ${vcf} -M ${pop_id} ${args}


        """ 
}
