process VCFTOOLS_CONCAT{

    tag { "concate_vcf" }
    label "process_medium"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/${process}/vcftools/concat/", mode:"copy")

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

    vcf-concat $vcf|bgzip -c > ${file_prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


        """ 
}
