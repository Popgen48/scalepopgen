process GAWK_PREPARE_NEW_MAP{

    tag { "preparing_new_map" }
    label "process_single"
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"    
    publishDir("${params.outdir}/gawk/prepare_new_map/", mode:"copy")

    input:
        path(map_f)
        path(unrel_id)

    output:
        path("*new_sample_pop.map"), emit: txt
        path "versions.yml", emit: versions
       
    
    script:
        outprefix = params.outprefix

        if (params.mind > 0 || params.king_cutoff > 0 ){

        """
    awk 'NR==FNR{sample_id[\$1];next}\$1 in sample_id{print}' ${unrel_id} ${map_f} > ${outprefix}_new_sample_pop.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS


        """ 

        }
        
        else{
            
                
        """

    awk 'NR==FNR{sample_id[\$1];next}!(\$1 in sample_id){print}' ${unrel_id} ${map_f} > ${outprefix}_new_sample_pop.map

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS

        """        
        }
            
}
