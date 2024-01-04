/* 
*subworkflow to run PCA and ADMIXTURE analysis
*/

include { GAWK_UPDATE_CHROM_IDS          } from '../../modules/local/gawk/update_chrom_ids/main'
include { PLINK_MAKE_BED                 } from '../../modules/local/plink/make_bed/main'
include { ADMIXTURE                      } from '../../modules/nf-core/admixture/main'
include { PYTHON_PLOT_ADMIXTURE_CV_ERROR } from '../../modules/local/python/plot/admixture/cv_error/main'
include { PYTHON_PLOT_ADMIXTURE_Q_MAT    } from '../../modules/local/python/plot/admixture/q_mat/main'

workflow RUN_ADMIXTURE{
    take:
        bed
        m_pop_sc_color

    main:
        if(params.allow_extra_chrom){
            if(!params.chrom_map){
                //
                //MODULE: GAWK_UPDATE_CHROM_IDS
                //
                GAWK_UPDATE_CHROM_IDS(
                    bed.map{meta,bed->bed[1]}
                )
                chrom_map = GAWK_UPDATE_CHROM_IDS.out.map
            }
            else{
                chrom_map = Channel.fromPath(params.chrom_map, checkIfExists: true)
            }
            //
            //MODULE: PLINK2_MAKE_BED --> with updated chromosome ids
            //
            PLINK_MAKE_BED(
                bed,
                chrom_map
            )
            n2_bed = PLINK_MAKE_BED.out.bed
        }
        else{
            n2_bed = bed
        }
        //
        //MODULE: ADMIXTURE
        //
        k = Channel.from(params.start_k..params.end_k)
        ADMIXTURE(
            n2_bed.map{meta,bed->tuple(meta,bed[0],bed[1],bed[2])}.combine(k)
        )

        //
        // MODULE: PYTHON_PLOT_ADMIXTURE_CV_ERROR
        //
        PYTHON_PLOT_ADMIXTURE_CV_ERROR(
                ADMIXTURE.out.log.collect()
        )
        
        //
        //MODULE: PYTHON_PLOT_ADMIXTURE_Q_MAT
        //
        admixture_colors         = Channel.fromPath(params.admixture_colors, checkIfExists: true)
        admixture_plot_yml       = Channel.fromPath(params.admixture_plot_yml, checkIfExists: true)
        admixture_plot_pop_order = params.admixture_plot_pop_order ?:[]
        PYTHON_PLOT_ADMIXTURE_Q_MAT(
            ADMIXTURE.out.ancestry_fractions.map{meta,q_mat->q_mat}.collect(),
            n2_bed.map{meta,bed->bed[2]},
            admixture_colors,
            admixture_plot_yml,
            admixture_plot_pop_order
        )
            
}
