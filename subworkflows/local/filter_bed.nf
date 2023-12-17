include { FILTER_SAMPLES } from '../../modules/local/plink2/filter_samples/main'
include { FILTER_SNPS    } from '../../modules/local/plink2/filter_snps/main'

workflow FILTER_BED{
    take:
        bed
    main:
        if(params.apply_indi_filters){
            //
            //MODULE: FILTER_SAMPLES
            //
            FILTER_SAMPLES(
                INPUT_CHECK.out.variant,
                is_vcf
            )
            n0_meta_bed = FILTER_SAMPLES.out.n1_meta_bed
        }
        else{
                n0_meta_bed = INPUT_CHECK.out.variant
        }
        if (params.apply_snp_filters ){
            //
            //MODULE: FILTER_SNPS
            //
            FILTER_SNPS(
                n0_meta_bed
            )
            n1_meta_bed = FILTER_SNPS.out.n1_meta_bed
        }
        else{
            n1_meta_bed = n0_meta_bed
        }

    emit:
        n1_meta_bed = n1_meta_bed
}
