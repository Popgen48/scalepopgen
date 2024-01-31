/* 
*subworkflow to cluster samples based on NJ distance calculated based on pairwise 1-minus ibs distance
*/

include { PLINK_CALC_1_MIN_IBS_DIST      } from '../../modules/local/plink/calc_1_min_ibs_dist/main'
include { PYTHON_PLOT_1_MIN_IBS_DIST     } from '../../modules/local/python/plot/1_min_ibs_dist/main'

workflow CALC_1_MIN_IBS_DIST{
    take:
        bed
        m_pop_sc_color

    main:
        //
        //MODULE: PLINK_CALC_1_MIN_IBS
        //
        PLINK_CALC_1_MIN_IBS_DIST(
            bed
        )

        //
        //MODULE: PYTHON_PLOT_1_MIN_IBS_DIST
        //
        ibs_plot_yml = Channel.fromPath(params.ibs_plot_yml, checkIfExists: true)
        PYTHON_PLOT_1_MIN_IBS_DIST(
            PLINK_CALC_1_MIN_IBS_DIST.out.mdist,
            PLINK_CALC_1_MIN_IBS_DIST.out.id,
            m_pop_sc_color,
            ibs_plot_yml
        )
        html = PYTHON_PLOT_1_MIN_IBS_DIST.out.html

    emit:
        html
}
