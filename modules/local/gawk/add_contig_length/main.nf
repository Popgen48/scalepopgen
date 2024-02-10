process GAWK_ADD_CONTIG_LENGTH{

    tag { "adding_contig_length" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/gawk/add_contig_length/", mode:"copy")

    input:
        tuple val(meta), path(vcf)
        path(chrom_length_map)
        

    output:
        tuple val(n_meta), path("${outprefix}.vcf"), emit:vcf
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        
        outprefix = params.outprefix
        n_meta = [:]
        n_meta.id = outprefix
	
        """

    awk 'NR==FNR{chrm_len[\$1]=\$2;next}{if(\$0~/^##contig/){match(\$0,/(##contig=<ID=)([^>]+)(>)/,a);print a[1]a[2]",length="chrm_len[a[2]]a[3];next}else{print}}' ${chrom_length_map} ${vcf} > ${outprefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 

}
