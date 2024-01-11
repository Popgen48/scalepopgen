include { PLINK2_SAMPLE_COUNTS                } from '../../modules/local/plink2/sample_counts/main'
include { VCFTOOLS_DEPTH                      } from '../../modules/local/vcftools/depth/main'
include { PYTHON_COLLECT_INDIV_SUMMARY_PLINK  } from '../../modules/local/python/collect/indiv_summary_plink/main'
include { GAWK_COLLECT_INDIV_SUMMARY_VCF      } from '../../modules/local/gawk/collect_indiv_summary_vcf/main'

workflow PREPARE_INDIV_REPORT{
    take:
        meta_vcf_idx_map
        is_vcf
    main:
        //
        //MODULE: CALC_INDIV_SUMMARY
        //
        PLINK2_SAMPLE_COUNTS(
            is_vcf ? meta_vcf_idx_map.map{meta, vcf, idx, map->tuple(meta,vcf)} : meta_vcf_idx_map,
            is_vcf
        )
        //
        //MODULE: INDIV_SUMMARY_PLINK
        //
        PYTHON_COLLECT_INDIV_SUMMARY_PLINK(
            PLINK2_SAMPLE_COUNTS.out.samplesummary.collect(),
            is_vcf
        )
        if (is_vcf){
            //
            //MODULE: VCFTOOLS_DEPTH
            //
            VCFTOOLS_DEPTH(
            is_vcf ? meta_vcf_idx_map.map{meta, vcf, idx, map->tuple(meta,vcf)} : meta_vcf_idx_map
            )
            //
            //MODULE: INDIV_SUMMARY_VCF
            //
            GAWK_COLLECT_INDIV_SUMMARY_VCF(
                VCFTOOLS_DEPTH.out.sampledepthinfo.collect(),
                PYTHON_COLLECT_INDIV_SUMMARY_PLINK.out.genomewidesummaryplink
            )
        }
}
