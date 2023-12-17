process VCFTOOLS_CONCAT{

    tag { "concate_vcf" }
    label "process_medium"
    conda "bioconda::vcftools=0.1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"
    //publishDir("${params.outdir}/${process}/input/", mode:"copy")

    input:
        path(vcf)
        val(process)

    output:
        tuple val(meta), path ("${file_prefix}.vcf.gz"), emit: concatenatedvcf

    script:
        meta= [:]
        meta.id = params.outprefix
        file_prefix = params.outprefix

        """
        vcf-concat $vcf|gzip -c > ${file_prefix}.vcf.gz

        """ 
}
