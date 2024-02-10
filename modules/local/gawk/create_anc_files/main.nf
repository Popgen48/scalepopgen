process GAWK_CREATE_ANC_FILES{

    tag { "${chrom}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outDir}/selection/ancestral_alleles_determination/est-sfs/", mode:"copy")

    input:
        tuple val(meta), path(map), path(pvalue)

    output:
        tuple val(meta), path ("*.anc"), emit: anc
         path "versions.yml", emit: versions
    
    script:
        chrom = meta.id

        """

        awk 'NR==FNR{chrom[NR]=\$1;pos[NR]=\$2;major_allele[NR]=\$3;next}FNR>7{if(\$3<0.5){major_allele[\$1]==0 ? anc_allele=1 : anc_allele=0}else{anc_allele=major_allele[\$1]}anc_allele==1 ? der_allele=0:der_allele=1;print chrom[\$1],pos[\$1],anc_allele,der_allele}' ${map} ${pvalue} > ${chrom}.anc

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """ 
}
