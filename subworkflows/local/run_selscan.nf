/* 
* workflow to carry out signature of selection using phased data
*/

include { PYTHON_SPLIT_MAP as SPLIT_MAP_SELSCAN    } from '../../modules/local/python/split_map/main'
include { GAWK_PREPARE_RECOMB_MAP_SELSCAN          } from '../../modules/local/gawk/prepare_recomb_map_selscan/main'
include { VCFTOOLS_KEEP as SPLIT_VCF_BY_POP        } from '../../modules/local/vcftools/keep/main'
include { SELSCAN_METHOD as SELSCAN_IHS            } from '../../modules/local/selscan/method/main'
include { SELSCAN_NORM as SELSCAN_NORM_IHS         } from '../../modules/local/selscan/norm/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_IHS_RESULTS  } from '../../modules/local/python/collect/selection_results/main'

def PREPARE_PAIRWISE_VCF( file_list_pop ){

        file1 = file_list_pop.flatten()
        file2 = file_list_pop.flatten()
        file_pairs = file1.combine(file2)
        file_pairsB = file_pairs.branch{ file1_path, file2_path ->

            samePop : file1_path == file2_path
                return tuple(file1_path, file2_path).sort()
            diffPop : file1_path != file2_path && file1_path.baseName.split("__")[0] == file2_path.baseName.split("__")[0]
                return tuple(file1_path, file2_path).sort()
        
        }
        return file_pairsB.diffPop

}

def change_meta_in_channel( meta_file ){
        
        def n_meta = [:]
        suffix = meta_file[0].id
        pattern = ~/${suffix}_/
        vcf_prefix = meta_file[1].getName().minus(".vcf.gz")
        n_meta.id = (vcf_prefix - pattern)
        n_meta_vcf_recombmap = [n_meta,meta_file[1],meta_file[2]]
        return n_meta_vcf_recombmap


}

workflow RUN_SELSCAN{
    take:

        chrom_vcf_idx_map

    main:

        //
        //MODULE: SPLIT_MAP_SELSCAN
        //
        // input for split_vcf_by_pop //

        map_f = chrom_vcf_idx_map.map{ chrom, vcf, idx, map_f -> map_f }.unique()

        SPLIT_MAP_SELSCAN(
            map_f,
            Channel.value("selscan")
        )

        pop_file = SPLIT_MAP_SELSCAN.out.poptxt.flatten()

        
        chrom_vcf_idx_map_pop = chrom_vcf_idx_map.combine(pop_file)
        
        //preparing map file ihs and XP-EHH analysis, needed by selscan


        if( params.selscan_map ){
            Channel
                .fromPath(params.selscan_map)
                .splitCsv(header:true)
                .map{row -> if(!file(row.recomb_map).exists() ){ exit 1, 'ERROR: input recomb file does not exist  \
                    -> ${row.recomb_map}' }else{tuple(row.id, file(row.recomb_map))} }
                .set{ n1_chrom_recombmap }
        }
        else{
                GAWK_PREPARE_RECOMB_MAP_SELSCAN( 
                    chrom_vcf_idx_map_pop.map{meta, vcf, idx, map, pop->tuple(meta,vcf)}.unique() 
                )
                n1_chrom_recombmap = GAWK_PREPARE_RECOMB_MAP_SELSCAN.out.meta_selscanmap
        }


        //MODULE: SPLIT_VCF_BY_POP
        //

        SPLIT_VCF_BY_POP(
            chrom_vcf_idx_map_pop,
            Channel.value("selscan")
        )


        // make pairwise tuple of splitted (based on pop id) phased vcf files 

        ihs_input = SPLIT_VCF_BY_POP.out.vcf.combine(n1_chrom_recombmap, by:0).map{change_meta_in_channel(it)}

        ihs_input.view()
        
        //
        //MODULE: SELSCAN_IHS
        //
        SELSCAN_IHS(
            ihs_input.map{meta,vcf,rmap->tuple(meta,vcf,[],rmap)},
            Channel.value("ihs")
        )

        //
        //MODULE: SELSCAN_NORM_IHS
        //
        SELSCAN_NORM_IHS(
            SELSCAN_IHS.out.groupTuple(),
            Channel.value("ihs")
        )

        //
        //MODULE: COLLECT_IHS_RESULTS
        //

        COLLECT_IHS_RESULTS(
            SELSCAN_NORM_IHS.out.txt,
            Channel.value("ihs")
        )
}
