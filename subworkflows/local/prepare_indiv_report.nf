include { PLINK2_SAMPLE_COUNTS                              } from '../../modules/local/plink2/sample_counts/main'
include { PLINK_CALC_MAF; PLINK_CALC_MAF as PLINK_CALC_HARDY  } from '../../modules/local/plink/calc_maf/main'
include { PYTHON_PLOT_SAMPLE_STATS                          } from '../../modules/local/python/plot/sample_stats/main'
include { GAWK_MAKE_CLUSTER_FILE as GAWK_MAF_CALC_INPUT     } from '../../modules/local/gawk/make_cluster_file/main'
include { PYTHON_PLOT_AVERAGE_MAF                           } from '../../modules/local/python/plot/average_maf/main'
include { GAWK_SPLIT_FAM_FILE                               } from '../../modules/local/gawk/split_fam_file/main'
include { PYTHON_PLOT_AVERAGE_HET                           } from '../../modules/local/python/plot/average_het/main'
include { MULTIQC as MULTIQC_INDIV_REPORT                   } from '../../modules/nf-core/multiqc/main'

workflow PREPARE_INDIV_REPORT{
    take:
        meta_bed
        color_file
    main:
        //
        //MODULE: PLINK_SAMPLE_COUNTS
        //
        PLINK2_SAMPLE_COUNTS(
            meta_bed
        )

        //
        //MODULE: PYTHON_PLOT_SAMPLE_STATS
        // 
        PYTHON_PLOT_SAMPLE_STATS(
            PLINK2_SAMPLE_COUNTS.out.samplesummary,
        )

        //
        //MODULE: GAWK_MAF_CALC_INPUT
        //
        GAWK_MAF_CALC_INPUT(
            meta_bed.map{meta,bed->bed[2]}
        )

        //
        //MODULE: PLINK2_MAF_CALC
        //
        PLINK_CALC_MAF(
            meta_bed,
            GAWK_MAF_CALC_INPUT.out.txt,
            Channel.value("freq")
        )
        
        //
        //MODULE: PYTHON_PLOT_AVERAGE_MAF
        //
        PYTHON_PLOT_AVERAGE_MAF(
            meta_bed.map{meta,bed->bed[1]},
            color_file,
            PLINK_CALC_MAF.out.mafsummary
        )
        
        //
        //MODULE: GAWK_SPLIT_FAM_FILE
        //
        GAWK_SPLIT_FAM_FILE(
            meta_bed.map{meta,bed->bed[2]}
        )
        
        popid_file = GAWK_SPLIT_FAM_FILE.out.txt.flatten()

        input_c = meta_bed.combine(popid_file).multiMap{meta, bed, popid ->
                                                    meta_bed: tuple(meta,bed)
                                                    popid: popid
                                                   }
        //
        //MODULE PLINK_CALC_HARDY
        //
        PLINK_CALC_HARDY(
            input_c.meta_bed,
            input_c.popid,
            Channel.value("hwe")
        )

        //
        //MODULE: PYTHON_PLOT_AVERAGE_HET
        //
        PYTHON_PLOT_AVERAGE_HET(
            meta_bed.map{meta,bed->bed[1]},
            color_file,
            PLINK_CALC_HARDY.out.hwesummary.collect(),
        )
        
        ch_multiqc_files = PYTHON_PLOT_SAMPLE_STATS.out.sample_stats_html.combine(PYTHON_PLOT_AVERAGE_MAF.out.maf_stats_html).combine(PYTHON_PLOT_AVERAGE_HET.out.obs_het_html).combine(PYTHON_PLOT_AVERAGE_HET.out.exp_het_html)

        multiqc_config = Channel.fromPath(params.multiqc_summary_stats_yml)
        
        //
        //MODULE: MULTIQC_INDIV_REPORT
        //
        MULTIQC_INDIV_REPORT(
            ch_multiqc_files,
            multiqc_config,
            [],
            []
        )
}
