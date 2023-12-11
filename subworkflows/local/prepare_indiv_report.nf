include { PLINK2_SAMPLE_COUNTS } from '../../modules/local/plink2/sample_counts/main'
include { VCFTOOLS_DEPTH       } from '../../modules/local/vcftools/depth/main'
include { INDIV_SUMMARY_PLINK  } from '../../modules/local/indiv_summary/plink/main'
include { INDIV_SUMMARY_VCF    } from '../../modules/local/indiv_summary/vcf/main'

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
        INDIV_SUMMARY_PLINK(
            PLINK2_SAMPLE_COUNTS.out.samplesummary.collect()
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
            INDIV_SUMMARY_VCF(
                VCFTOOLS_DEPTH.out.sampledepthinfo.collect(),
                INDIV_SUMMARY_PLINK.out.genomewidesummaryplink
            )
        }
}
