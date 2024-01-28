process VCFTOOLS_CONCAT{

    tag { "concate_vcf" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"

    input:
        path(vcf)
        val(process)

    output:
        tuple val(meta), path ("${file_prefix}.vcf.gz"), emit: concatenatedvcf
        path "versions.yml", emit: versions

    script:
        meta= [:]
        meta.id = params.outprefix
        file_prefix = params.outprefix

        """

    vcf-concat $vcf|gzip -c > ${file_prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


        """ 
}
