/* 
*subworkflow to run PCA and ADMIXTURE analysis
*/

include { GAWK_MAKE_CLUSTER_FILE         } from '../../modules/local/gawk/make_cluster_file/main'
include { PLINK2_CALC_PAIRWISE_FST       } from '../../modules/local/plink2/calc_pairwise_wfst/main'
include { PYTHON_PLOT_PAIRWISE_FST       } from '../../modules/local/python/plot/pairwise_fst/main'

workflow CALC_FST{
    take:
        bed
        m_pop_sc_color

    main:
        //
        //MODULE: GAWK_UPDATE_CHROM_IDS
        //
        GAWK_MAKE_CLUSTER_FILE(
            bed.map{meta,bed->bed[2]}
        )

        //
        //MODULE: PLINK2_CALC_PAIRWISE_FST
        //
        PLINK2_CALC_PAIRWISE_FST(
            bed,
            GAWK_MAKE_CLUSTER_FILE.out.txt,
        )
        //
        //MODULE: PYTHON_PLOT_PAIRWISE_FST
        //
        fst_plot_yml = Channel.fromPath(params.fst_plot_yml, checkIfExists: true)
        PYTHON_PLOT_PAIRWISE_FST(
            PLINK2_CALC_PAIRWISE_FST.out.fst_mat,
            m_pop_sc_color,
            fst_plot_yml
        )
}
