/* 
*subworkflow to run PCA and ADMIXTURE analysis
*/

include { PLINK2_EXPORT_PED              } from '../../modules/local/plink2/export_ped/main'
include { PYTHON_CREATE_EIGENSTRAT_PAR   } from '../../modules/local/python/create/eigenstrat_par/main'
include { GAWK_MODIFY_PHENO_COL_PED      } from '../../modules/local/gawk/modify_pheno_col_ped/main'
include { EIGENSOFT_CONVERTF             } from '../../modules/local/eigensoft/convertf/main'
include { PYTHON_CREATE_SMARTPCA_PAR     } from '../../modules/local/python/create/smartpca_par/main'
include { EIGENSOFT_SMARTPCA             } from '../../modules/local/eigensoft/smartpca/main'
include { PYTHON_PLOT_PCA                } from '../../modules/local/python/plot/pca/main'


workflow RUN_PCA{
    take:
        bed
        m_pop_sc_color

    main:
                //
                //MODULE: PLINK2_EXPORT_PED
                //
                PLINK2_EXPORT_PED(
                    bed
                )
                
                //
                //MODULE: CREATE_EIGENSTRAAT
                //
                PYTHON_CREATE_EIGENSTRAT_PAR(
                    PLINK2_EXPORT_PED.out.ped.map{meta,ped->meta}
                )
                //
                //MODULE: GAWK_MODIFY_PHENO_COL_PED
                //
                GAWK_MODIFY_PHENO_COL_PED(
                    PLINK2_EXPORT_PED.out.ped
                )
                //
                //MODULE: EIGENSOFT_CONVERTF
                //
                EIGENSOFT_CONVERTF(
                    PLINK2_EXPORT_PED.out.ped.map{meta,pedmap->tuple(meta,pedmap[0])}.combine(GAWK_MODIFY_PHENO_COL_PED.out.ped, by:0),
                    PYTHON_CREATE_EIGENSTRAT_PAR.out.eigenpar
                )
                //
                //MODULE: CREATE_SMARTPCA_PAR
                //
                PYTHON_CREATE_SMARTPCA_PAR(
                    PLINK2_EXPORT_PED.out.ped.map{meta,ped->meta}
                )
                //
                //MODULE: EIGENSOFT_SMARTPCA
                //
                EIGENSOFT_SMARTPCA(
                    EIGENSOFT_CONVERTF.out.eigenstratgeno,
                    PYTHON_CREATE_SMARTPCA_PAR.out.smartpcapar
                )
                //
                //MODULE: PLOT_PCA
                //
                pca_plot_yml = Channel.fromPath(params.pca_plot_yml, checkIfExists: true)
                marker_map = params.marker_map ? Channel.fromPath(params.marker_map, checkIfExists: true) : []

                PYTHON_PLOT_PCA(
                    EIGENSOFT_SMARTPCA.out.evec,
                    EIGENSOFT_SMARTPCA.out.eval,
                    m_pop_sc_color,
                    pca_plot_yml,
                    marker_map
                )
        html=PYTHON_PLOT_PCA.out.html
    emit:
        html
}
