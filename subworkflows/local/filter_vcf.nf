include { VCFTOOLS_CONCAT               } from '../../modules/local/vcftools/concat/main'
include { VCFTOOLS_KEEP                 } from '../../modules/local/vcftools/keep/main'
include { FILTER_SAMPLES                } from '../../modules/local/plink2/filter_samples/main'
include { GAWK_PREPARE_NEW_MAP          } from '../../modules/local/gawk/prepare_new_map/main'
include { VCFTOOLS_REMOVE               } from '../../modules/local/vcftools/remove/main'
include { VCFTOOLS_FILTER_SITES         } from '../../modules/local/vcftools/filter_sites/main'
include { LOCAL_TABIX_BGZIPTABIX        } from '../../modules/local/bgziptabix/main'
include { GAWK_EXTRACT_SAMPLEID; GAWK_EXTRACT_SAMPLEID as REMOVE_SAMPLE_LIST } from '../../modules/local/gawk/extract_sampleid/main'

workflow FILTER_VCF{
    take:
        meta_vcf_idx_map
        is_vcf

    main:
        if( params.apply_indi_filters ){
        
            o_map = meta_vcf_idx_map.map{meta, vcf, idx, map_f -> map_f}.unique()

            if ( params.rem_indi ){
                
                rif = Channel.fromPath(params.rem_indi, checkIfExists: true)

                //
                //MODULE: GAWK_EXTRACT_SAMPLEID
                //
                REMOVE_SAMPLE_LIST(
                    rif,
                    Channel.value("remove")
                )
                    
            }

            /* --> king_cutoff and missingness filter should be based on the entire genome therefore vcf file should be concatenated first and then 
                   supply to plink. From plink module, the list of individuals to be kept is piped out and supply to keep indi module. This module will
                   then extract these sets of individuals from each chromosome file separately. Note that if custom individuals to be removed are also
                    supplied then this will be considered in extract_unrelated_sample_list module as well. 
            */      
    
            if( params.king_cutoff > 0 || params.mind > 0 ){


                vcflist = meta_vcf_idx_map.map{meta, vcf, idx, map_f -> vcf}.collect()


                //
                // MODULE: CONCAT_VCF
                //

                VCFTOOLS_CONCAT(
                    vcflist,
                    Channel.value("filtering")
                )

                //
                // MODULE: FILTER_SAMPLES
                //
                FILTER_SAMPLES( 
                    VCFTOOLS_CONCAT.out.concatenatedvcf,
                    is_vcf,
                    params.rem_indi ? REMOVE_SAMPLE_LIST.out.txt : []
                )

                //
                // MODULE : GAWK_EXTRACT_SAMPLEID
                //
                GAWK_EXTRACT_SAMPLEID(
                    FILTER_SAMPLES.out.bed.map{meta,bed->bed[2]},
                    Channel.value("keep")
                )

                //
                // MODULE: VCFTOOLS_KEEP
                // 
                VCFTOOLS_KEEP(
                    meta_vcf_idx_map.combine(GAWK_EXTRACT_SAMPLEID.out.txt)
                )

                //
                // MODULE: GAWK_PREPARE_NEW_MAP
                //
                GAWK_PREPARE_NEW_MAP(
                    meta_vcf_idx_map.map{meta,vcf,idx,map->map}.unique(),
                    GAWK_EXTRACT_SAMPLEID.out.txt
                )
                n0_meta_vcf_idx_map = VCFTOOLS_KEEP.out.vcf.combine(GAWK_PREPARE_NEW_MAP.out.txt).map{meta,vcf,map->tuple(meta,vcf,[],map)}           

            }
            else{
                //
                //MODULE: VCFTOOLS_REMOVE
                //
                VCFTOOLS_REMOVE(
                    meta_vcf_idx_map.map{meta,vcf,idx,map->tuple(meta,vcf,idx)}.combine(rif)
                )

                //
                //MODULE: GAWK_PREPARE_NEW_MAP
                //
                GAWK_PREPARE_NEW_MAP(
                     meta_vcf_idx_map.map{meta,vcf,idx,map->map}.unique(),
                    rif
                )
                n0_meta_vcf_idx_map = VCFTOOLS_REMOVE.out.vcf.combine(GAWK_PREPARE_NEW_MAP.out.txt).map{meta,vcf,map->tuple(meta,vcf,[],map)}
            }
    }
    else{
        n0_meta_vcf_idx_map = meta_vcf_idx_map
    }
    if(params.apply_snp_filters){

            n_map = n0_meta_vcf_idx_map.map{meta,vcf,idx,map->map}.unique()
            //
            //MODULE: VCFTOOLS_FILTER_SITES
            //
            VCFTOOLS_FILTER_SITES(
                n0_meta_vcf_idx_map.map{meta,vcf,idx,map->tuple(meta,vcf)}
            )
            n1_meta_vcf_idx_map = VCFTOOLS_FILTER_SITES.out.vcf.combine(n_map).map{meta,vcf,map->tuple(meta,vcf,[],map)}
    }
    else{
        n1_meta_vcf_idx_map = n0_meta_vcf_idx_map
    }
    
    n1_map = n1_meta_vcf_idx_map.map{meta,vcf,idx,map->map}.unique()
    //
    //MODULE: LOCAL_TABIX_BGZIPTABIX
    //
    LOCAL_TABIX_BGZIPTABIX(
        n1_meta_vcf_idx_map.map{meta,vcf,idx,map->tuple(meta,vcf)}
    )
    
    n2_meta_vcf_idx_map = LOCAL_TABIX_BGZIPTABIX.out.gz_tbi.combine(n1_map)

    emit:
        n1_meta_vcf_idx_map = n2_meta_vcf_idx_map
}
