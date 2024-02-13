/* 
* workflow to carry out signature of selection using phased data
*/

include { PYTHON_SPLIT_MAP as SPLIT_MAP_SELSCAN    } from '../../modules/local/python/split_map/main'
include { GAWK_PREPARE_RECOMB_MAP_SELSCAN          } from '../../modules/local/gawk/prepare_recomb_map_selscan/main'
include { VCFTOOLS_KEEP as SPLIT_VCF_BY_POP        } from '../../modules/local/vcftools/keep/main'
include { SELSCAN_METHOD as SELSCAN_IHS            } from '../../modules/local/selscan/method/main'
include { SELSCAN_NORM as SELSCAN_NORM_IHS         } from '../../modules/local/selscan/norm/main'
include { SELSCAN_METHOD as SELSCAN_XPEHH          } from '../../modules/local/selscan/method/main'
include { SELSCAN_NORM as SELSCAN_NORM_XPEHH       } from '../../modules/local/selscan/norm/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_IHS_RESULTS  } from '../../modules/local/python/collect/selection_results/main'
//include { PYTHON_PLOT_SELECTION_RESULTS as PLOT_IHS                       } from '../../modules/local/python/plot/selection_results/main'

/*
* Arrange the grouped tuple to list of unique pairwise files
* for example input is --> [[id:chrom1],[chrom1_pop1.vcf.gz, chrom1_pop2.vcf.gz, chrom1_pop3.vcf.gz]]
* output is --> [[[id:chrom1],chrom1_pop1.vcf.gz, chrom1_pop2.vcf.gz],[[id:chrom1],chrom1_pop1.vcf.gz,chrom1_pop3.vcf.gz],[[id:chrom1],chrom1_pop2.vcf.gz, chrom1_pop3.vcf.gz]]
*/
def prepare_pairwise_vcf( it ){
    files = it[1]
    new_tuple = []
    for(i in 0 .. files.size()-1){
        new_files = files[i..files.size()-1]
        for(j in 0 .. new_files.size()-1){
            if(files[i] != new_files[j]){
             new_tuple.add([it[0],[files[i],new_files[j]]])
            }
        }
    }
    return new_tuple.sort()
}

def change_meta_in_channel_xpehh(meta_file){
    def n_meta = [:]
    suffix = meta_file[0].id
    pattern = ~/${suffix}_/
    vcf_prefix1 = meta_file[1].getName().minus(".vcf.gz")
    vcf_prefix2 = meta_file[2].getName().minus(".vcf.gz")
    id_list = [(vcf_prefix1-pattern),(vcf_prefix2-pattern)].sort()
    n_meta.id = id_list[0]+"_"+id_list[1]
    if(id_list[0] == vcf_prefix1 - pattern){
        n_meta_vcf1_vcf2_recombmap = [n_meta, meta_file[1], meta_file[2], meta_file[3]]
    }
    else{
        n_meta_vcf1_vcf2_recombmap = [n_meta, meta_file[2], meta_file[1], meta_file[3]]
    }
    return n_meta_vcf1_vcf2_recombmap
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
            params.chrom_id_map ? SELSCAN_NORM_IHS.out.txt.combine(Channel.fromPath(params.chrom_id_map, checkIfExists: true)) : SELSCAN_NORM_IHS.out.txt.map{meta,o_files->tuple(meta,o_files,[])},
            Channel.value("ihs")
        )
        //prepare xpehh input Channel
        
        ch_xpehh_grouped = SPLIT_VCF_BY_POP.out.vcf.groupTuple().map{it->prepare_pairwise_vcf(it)}
        ch_xpehh = ch_xpehh_grouped.flatten().collate(3).combine(n1_chrom_recombmap, by:0).map{change_meta_in_channel_xpehh(it)}

        //
        //MODULE: SELSCAN_XPEHH
        //
        SELSCAN_XPEHH(
            ch_xpehh,
            Channel.value("xpehh")
        )

        //
        //MODULE: SELSCAN_NORM_XPEHH
        //

        SELSCAN_NORM_XPEHH(
            SELSCAN_XPEHH.out.groupTuple(),
            Channel.value("xpehh")
        )
}
