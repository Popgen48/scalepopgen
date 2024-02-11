process GAWK_PREPARE_RECOMB_MAP_SELSCAN{

    tag { "${chrom}" }
    label "process_single"
    conda "conda-forge::gawk==5.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/selection/selscan/input_files", mode:"copy")

    input:
        tuple val( meta ), path( vcf )

    output:
        tuple val( meta ), path ( "${prefix}.map" ), emit: meta_selscanmap
        path "versions.yml", emit: versions

    script:

        chrom = meta.id
        def cm_to_bp = 1000000
        prefix = vcf.baseName
        
        """
                        

    zcat ${vcf}|awk '\$0!~/#/{sum++;print \$1,"locus"sum,\$2/${cm_to_bp},\$2}' > ${prefix}.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS


        """ 
}
