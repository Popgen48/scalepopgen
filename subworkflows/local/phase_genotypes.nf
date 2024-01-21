include { BEAGLE5_BEAGLE                  } from '../../modules/nf-core/beagle5/beagle/main'
include { SHAPEIT5_PHASECOMMON            } from '../../modules/nf-core/shapeit5/phasecommon/main'
include { TABIX_TABIX as TABIX_PHASED_VCF } from '../../modules/nf-core/tabix/tabix/main'

workflow PHASE_GENOTYPES{
    take:
        meta_vcf_idx_map
    main:
        map_f = meta_vcf_idx_map.map{meta, vcf, idx, map->map}.unique()
        meta_vcf_idx = meta_vcf_idx_map.map{meta, vcf, idx, mp->tuple(meta, vcf, idx)}
        //check if phasing_panel csv file path is set
        if( params.phasing_panel ){
        Channel
                .fromPath( params.phasing_panel )
                .splitCsv(sep:",")
                .map{ i_chrom, i_vcf, i_idx -> if(!file(i_vcf).exists() || !(file(i_idx).exists())){ exit 1, 'ERROR: reference vcf file or its index does not exists-> ${i_vcf}' }else{tuple([id:i_chrom], file(i_vcf), file(i_idx))} }
                .set{ i_chrom_vcf_idx }
            meta_vcf_idx_pvcf_idx = meta_vcf_idx.combine(i_chrom_vcf_idx,by:0)        
        }
        else{
            meta_vcf_idx_pvcf_idx = meta_vcf_idx.combine([null]).combine([null])
        }
        //check if recombination map csv file path is set
        if( params.phasing_map ){
            Channel
                .fromPath(params.phasing_map)
                .splitCsv(sep:",")
                .map{ i_chrom, i_map -> if(!file(i_map).exists() ){ exit 1, 'ERROR: recombination map file does not exist -> ${i_map}' }else{tuple([id:i_chrom], file(i_map))}}
                .set{ i_chrom_map }
            meta_vcf_idx_pvcf_idx_recomb = meta_vcf_idx_pvcf_idx.combine(i_chrom_map, by:0)
        }
        else{
            meta_vcf_idx_pvcf_idx_recomb = meta_vcf_idx_pvcf_idx.combine([null])
        }
        if (params.beagle5){
            //prepare input channel for beagle5
            beagle_input = meta_vcf_idx_pvcf_idx_recomb.multiMap{meta, vcf, idx, pvcf, pvcf_idx, recomb -> 
                    meta_vcf:[meta,vcf]
                    pvcf: pvcf
                    recomb:recomb
            }
            //
            //MODULE : BEAGLE5_BEAGLE
            //
            BEAGLE5_BEAGLE(
                beagle_input.meta_vcf,
                params.phasing_panel? beagle_input.pvcf:[],
                params.phasing_map?beagle_input.recomb:[],
                [],
                []
            )
        }
        else{
            shapeit5_input = meta_vcf_idx_pvcf_idx_recomb.multiMap{ meta, vcf, idx, pvcf, pvcf_idx, recomb ->
                meta_vcf_idx_pedigee_region: [meta, vcf, idx, null, meta.id]
                meta_ref_idx:[meta, pvcf, pvcf_idx]
                meta_recomb:[meta, recomb]
            }
            //
            //MODULE: SHAPEIT5_PHASECOMMON
            //
            SHAPEIT5_PHASECOMMON(
                shapeit5_input.meta_vcf_idx_pedigee_region.map{meta, vcf, idx, ped, region->tuple(meta, vcf, idx,ped?:[], region)},
                shapeit5_input.meta_ref_idx.map{meta, pvcf, pvcf_idx->tuple(meta?:[], pvcf?:[], pvcf_idx?:[])},
                [[],[],[]],
                shapeit5_input.meta_recomb.map{meta, recomb->tuple(meta?:[], recomb?:[])}
            )
        }
        //
        //MODULE: TABIX_PHASED_VCF
        //
        TABIX_PHASED_VCF(
            params.beagle5 ? BEAGLE5_BEAGLE.out.vcf: SHAPEIT5_PHASECOMMON.out.phased_variant
        )
        
        n2_meta_vcf_idx_map = params.beagle5 ? BEAGLE5_BEAGLE.out.vcf.join(TABIX_PHASED_VCF.out.tbi).combine(map_f) : SHAPEIT5_PHASECOMMON.out.phased_variant.join(TABIX_PHASED_VCF.out.tbi).combine(map_f)


        emit:
            n3_meta_vcf_idx_map = n2_meta_vcf_idx_map

}
