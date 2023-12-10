process PREPARE_NEW_MAP{

    tag { "preparing_new_map" }
    label "process_single"
    publishDir("${params.outdir}/", mode:"copy")

    input:
        path(map_f)
        path(unrel_id)

    output:
        path("*new_sample_pop.map"), emit: n_map
        
    
    script:
        outprefix = params.outprefix

        if (params.mind > 0 || params.king_cutoff > 0 ){

        """
        awk 'NR==FNR{sample_id[\$1];next}\$1 in sample_id{print}' ${unrel_id} ${map_f} > ${outprefix}_new_sample_pop.map


        """ 

        }
        
        else{
            
                
        """

        awk 'NR==FNR{sample_id[\$2];next}!(\$1 in sample_id){print}' ${unrel_id} ${map_f} > ${outprefix}_new_sample_pop.map


        """        
        }
            
}
