include { FILTER_SAMPLES } from '../../modules/local/plink2/filter_samples/main'
include { FILTER_SNPS    } from '../../modules/local/plink2/filter_snps/main'

workflow FILTER_BED{
    take:
        bed
        is_vcf
    main:
        versions = Channel.empty()

        if(params.apply_indi_filters){
            //
            //MODULE: FILTER_SAMPLES
            //
            if(params.rem_indi){
                rmi = Channel.fromPath(params.rem_indi, checkIfExists: true)
            }
            FILTER_SAMPLES(
                bed,
                is_vcf,
                params.rem_indi ? rmi : []
            )
            n0_meta_bed = FILTER_SAMPLES.out.bed

            versions = versions.mix(FILTER_SAMPLES.out.versions)
        }
        else{
                n0_meta_bed = bed
        }
        if (params.apply_snp_filters ){
            
            if(params.rem_snps){
                rms = Channel.fromPath(params.rem_snps, checkIfExists: true)
            }
            //
            //MODULE: FILTER_SNPS
            //
            FILTER_SNPS(
                n0_meta_bed,
                params.rem_snps ? rms : []
            )
            n1_meta_bed = FILTER_SNPS.out.n1_meta_bed

            versions = versions.mix(FILTER_SNPS.out.versions)
        }
        else{
            n1_meta_bed = n0_meta_bed
        }

    emit:
        n1_meta_bed = n1_meta_bed
        versions
}
