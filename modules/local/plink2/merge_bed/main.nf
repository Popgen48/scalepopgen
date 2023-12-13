process PLINK2_MERGE_BED{
    tag "merging_bed"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a3.7--h9f5acd7_2' :
        'biocontainers/plink2:2.00a3.7--h9f5acd7_3' }"

    input:
    path(bed)
    path(m_sample)

    output:
    tuple val(meta_n), path("*.{bed,bim,fam}")    , emit: bed
    tuple val(meta_n), path("*.pvar.zst"), emit: pvar_zst, optional: true
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix
    def mem_mb = task.memory.toMega()
    meta_n = [:]
    meta_n.id = prefix
    """
    ls *.fam|sed 's/\\.fam//g' > prefix_list.txt
    
    plink2 \\
        --threads $task.cpus \\
        --memory $mem_mb \\
        $args \\
        --pmerge-list prefix_list.txt bfile \\
        --out ${prefix}
    
    awk 'NR==FNR{pop[\$1]=\$2;next}{\$1=pop[\$2];print}' ${m_sample} ${prefix}.fam > ${prefix}.1.fam
    
    rm ${prefix}.fam

    mv ${prefix}.1.fam ${prefix}.fam


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
