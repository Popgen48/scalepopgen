include { BEAGLE5_BEAGLE       } from '../../modules/nf-core/beagle5/beagle/main'

workflow PHASE_GENOTYPES{
    take:
        meta_vcf_idx_map
    main:
        meta_vcf = meta_vcf_idx_map.map{meta, vcf, idx, mp->tuple(meta, vcf)}
        //check if phasing_panel csv file path is set
        if( params.phasing_panel ){
        Channel
                .fromPath( params.phasing_panel )
                .splitCsv(sep:",")
                .map{ i_chrom, i_vcf -> if(!file(i_vcf).exists() ){ exit 1, 'ERROR: reference vcf file for imputatation does not exists-> ${i_vcf}' }else{tuple([id:i_chrom], file(i_vcf))} }
                .set{ i_chrom_vcf }
            meta_vcf_pvcf = meta_vcf.combine(i_chrom_vcf,by:0)        
        }
        else{
            meta_vcf_pvcf = meta_vcf.combine([null])
        }
        //check if recombination map csv file path is set
        if( params.phasing_map ){
            Channel
                .fromPath(params.phasing_map)
                .splitCsv(sep:",")
                .map{ i_chrom, i_map -> if(!file(i_map).exists() ){ exit 1, 'ERROR: recombination map file does not exist -> ${i_map}' }else{tuple([id:i_chrom], file(i_map))}}
                .set{ i_chrom_map }
            meta_vcf_pvcf_recomb = meta_vcf_pvcf.combine(i_chrom_map, by:0)
        }
        else{
            meta_vcf_pvcf_recomb = meta_vcf_pvcf.combine([null])
        }
        if (params.beagle5){
            //prepare input channel for beagle5
            beagle_input = meta_vcf_pvcf_recomb.multiMap{meta, vcf, pvcf, recomb -> 
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

}
