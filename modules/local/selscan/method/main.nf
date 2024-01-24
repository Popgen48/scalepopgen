process SELSCAN_METHOD{

    tag { "${method}" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/selscan:1.2.0a--h0fdf51a_4' :
        'biocontainers/selscan:1.2.0a--h0fdf51a_5' }"
    publishDir("${params.outdir}/selscan/${method}/unstandardized/${local_dir}/", mode:"copy")

    input:
        tuple val(meta), path(t_vcf), path(r_vcf), path(r_map)
        val(method)

    output:
        tuple val(meta), path ("*.out"), emit: txt

    script:
        
        local_dir = meta.id
        prefix = t_vcf.getSimpleName().minus(".vcf.gz")
        def args = task.ext.args ?: ''
        def args1 = method == "xpehh" ? " --xpehh "+args+ "--vcf-ref "+${r_vcf}:" --ihs "+ args
        


        """


        selscan ${args1} --vcf ${t_vcf} --map ${r_map} --out ${prefix} --threads ${task.cpus}


        """ 
        
}
