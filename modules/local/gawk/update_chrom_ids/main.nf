process GAWK_UPDATE_CHROM_IDS{

    tag { "updating_chrom_ids" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/admixture/gawk/update_chrom_ids/", mode:"copy")

    input:
        path(bim)

    output:
        path("${outprefix}_chrom.map"), emit: map
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        outprefix = params.outprefix

	"""
	    
    awk -v cnt=0 '{if(!(\$1 not in a)){a[\$1];cnt++};print \$2,cnt}' ${bim} > ${outprefix}_chrom.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

	    
	"""

}
