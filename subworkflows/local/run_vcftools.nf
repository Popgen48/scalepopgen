/* 
* workflow to carry out signature of selection ( unphased data )
*/

include { PYTHON_SPLIT_MAP as SPLIT_MAP_VCFTOOLS    } from '../../modules/local/python/split_map/main'
include { VCFTOOLS_CONCAT as CONCAT_VCF_SELECTION   } from '../../modules/local/vcftools/concat/main'
include { VCFTOOLS_SELECTION as VCFTOOLS_TAJIMAS_D  } from '../../modules/local/vcftools/selection/main'
include { VCFTOOLS_SELECTION as VCFTOOLS_PI         } from '../../modules/local/vcftools/selection/main'
include { VCFTOOLS_SELECTION as VCFTOOLS_PAIR_FST   } from '../../modules/local/vcftools/selection/main'
include { VCFTOOLS_SELECTION as VCFTOOLS_ALL_FST    } from '../../modules/local/vcftools/selection/main'
include { GAWK_PREPARE_FST_ALL_INPUT                } from '../../modules/local/gawk/prepare_fst_all_input/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_TAJIMAS_D } from '../../modules/local/python/collect/selection_results/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_ALL_FST   } from '../../modules/local/python/collect/selection_results/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_PI        } from '../../modules/local/python/collect/selection_results/main'
include { PYTHON_PLOT_SELECTION_RESULTS as PLOT_TAJIMAS_D                } from '../../modules/local/python/plot/selection_results/main'
include { PYTHON_PLOT_SELECTION_RESULTS as PLOT_ALL_FST                  } from '../../modules/local/python/plot/selection_results/main'
include { PYTHON_PLOT_SELECTION_RESULTS as PLOT_PI                       } from '../../modules/local/python/plot/selection_results/main'


def PREPARE_DIFFPOP_T( file_list_pop ){

        file1 = file_list_pop.flatten()
        file2 = file_list_pop.flatten()
        file_pairs = file1.combine(file2)
        file_pairsB = file_pairs.branch{ file1_path, file2_path ->

            samePop : file1_path == file2_path
                return tuple(file1_path, file2_path).sort()
            diffPop : file1_path != file2_path
                return tuple(file1_path, file2_path).sort()
        
        }
        return file_pairsB.diffPop

}



workflow RUN_VCFTOOLS{
    take:
        chrom_vcf_idx_map

    main:
        
        selection_plot_yml = Channel.fromPath(params.selection_plot_yml, checkIfExists: true)




        // sample map file should be processed separately to split id pop-wise

        map_f = chrom_vcf_idx_map.map{ chrom, vcf, idx, mp -> mp}.unique()


        //
        //MODULE: SPLIT_MAP_VCFTOOLS
        //

        SPLIT_MAP_VCFTOOLS(
            map_f,
            Channel.value("vcftools")
        )

        pop_file = SPLIT_MAP_VCFTOOLS.out.poptxt.flatten()

        
        if( !params.input.endsWith(".p.csv") ){
            if( params.skip_chromwise ){
                //
                //MODULE: CONCAT_VCF_SELECTION
                //
                CONCAT_VCF_SELECTION(
                    chrom_vcf_idx_map.map{chrom,vcf,idx,map->vcf}.collect(),
                    Channel.value("vcftools")
                )
                n0_chrom_vcf = CONCAT_VCF_SELECTION.out.concatenatedvcf
            }
            else{
                n0_chrom_vcf = chrom_vcf_idx_map.map{chrom,vcf,idx,map->tuple(chrom,vcf)}
            }
        }
        else{
            n0_chrom_vcf = chrom_vcf_idx_map.map{chrom,vcf,idx,map->tuple(chrom,vcf)}
        }
        
        n0_chrom_vcf_popid = n0_chrom_vcf.combine(pop_file)

        if( params.tajimas_d ){
            //
            //MODULE: VCFTOOLS_TAJIMAS_D
            //
            VCFTOOLS_TAJIMAS_D(
                n0_chrom_vcf_popid.map{chrom,vcf,popid->tuple(chrom,vcf,popid,[])},
                Channel.value("tajimas_d")
            )
            //
            //MODULE: COLLECT_TAJIMAS_D
            //
            COLLECT_TAJIMAS_D(
                params.chrom_id_map ? VCFTOOLS_TAJIMAS_D.out.txt.groupTuple().combine(Channel.fromPath(params.chrom_id_map,checkIfExists:true)) : VCFTOOLS_TAJIMAS_D.out.txt.groupTuple().map{meta,o_files->tuple(meta,o_files,[])},
                Channel.value("tajimas_d")
            )
        
            //
            //MODULE: PLOT_TAJIMAS_D
            //
            trct = COLLECT_TAJIMAS_D.out.cutoff.map{meta,c_file->c_file}.splitCsv(header:true).map{row->tuple([id:row.id],row.cutoff)}.combine(COLLECT_TAJIMAS_D.out.txt,by:0)

            PLOT_TAJIMAS_D(
                trct.combine(selection_plot_yml),
                Channel.value("tajimas_d")
            )
            
            l_t_html_files = PLOT_TAJIMAS_D.out.html

            //l_html_files.view()
            
        }
        if( params.pi_val ){
            //
            //MODULE: VCFTOOLS_PI
            //
            VCFTOOLS_PI(
                n0_chrom_vcf_popid.map{chrom,vcf,popid->tuple(chrom,vcf,popid,[])},
                Channel.value("pi_val")
            )
            //
            //MODULE: COLLECT_PI
            //
            COLLECT_PI(
                params.chrom_id_map ? VCFTOOLS_PI.out.txt.groupTuple().combine(Channel.fromPath(params.chrom_id_map,checkIfExists:true)) : VCFTOOLS_PI.out.txt.groupTuple().map{meta,o_files->tuple(meta,o_files,[])},
                Channel.value("pi_val")
            )
            //
            //MODULE: PLOT_PI
            //
            trcp = COLLECT_PI.out.cutoff.map{meta,c_file->c_file}.splitCsv(header:true).map{row->tuple([id:row.id],row.cutoff)}.combine(COLLECT_PI.out.txt,by:0)

            PLOT_PI(
                trcp.combine(selection_plot_yml),
                Channel.value("pi_value")
            )
            l_p_html_files = PLOT_PI.out.html
        }
        if( params.pairwise_local_fst){
            
            popfile_collect = pop_file.collect()
            
            //FUNCTION: PREPARE_DIFFPOP_T
            pop1_pop2 = PREPARE_DIFFPOP_T(popfile_collect).unique()

            //
            //MODULE: VCFTOOLS_PAIR_FST
            //
            VCFTOOLS_PAIR_FST(
                n0_chrom_vcf.combine(pop1_pop2),
                Channel.value("pairwise_fst")
            )

        }
        if( params.fst_one_vs_all ){
            //
            //MODULE: GAWK_PREPARE_FST_ALL_INPUT
            //
            GAWK_PREPARE_FST_ALL_INPUT(
                map_f.combine(pop_file)
            )
            n1_m_pop1_pop2 = pop_file.map{pop_file->tuple(pop_file.getName().minus(".txt"), pop_file)}.combine(GAWK_PREPARE_FST_ALL_INPUT.out.txt,by:0)
            n1_pop1_pop2 = n1_m_pop1_pop2.map{n,p1,p2->tuple(p1,p2)}
            
            //
            //MODULE: VCFTOOLS_ALL_FST
            //
            VCFTOOLS_ALL_FST(
                n0_chrom_vcf.combine(n1_pop1_pop2),
                Channel.value("fst_all")
            )
            //
            //MODULE: COLLECT_ALL_FST
            //
            COLLECT_ALL_FST(
                params.chrom_id_map ? VCFTOOLS_ALL_FST.out.txt.groupTuple().combine(Channel.fromPath(params.chrom_id_map,checkIfExists:true)) : VCFTOOLS_ALL_FST.out.txt.groupTuple().map{meta,o_files->tuple(meta,o_files,[])},
                Channel.value("fst_all")
            )
            //
            //MODULE: PLOT_ALL_FST
            // 
            trcf = COLLECT_ALL_FST.out.cutoff.map{meta,c_file->c_file}.splitCsv(header:true).map{row->tuple([id:row.id],row.cutoff)}.combine(COLLECT_ALL_FST.out.txt,by:0)

            PLOT_ALL_FST(
                trcf.combine(selection_plot_yml),
                Channel.value("fst_values")
            )
            
            l_f_html_files = PLOT_ALL_FST.out.html
            
        }
        
        /*
        l_html_files = params.tajimas_d ? l_t_html_files: []
        l_html_files = params.pi_val ? (params.tajimas_d ? l_html_files.combine(l_p_html_files, by:0): l_p_html_files):l_html_files
        l_html_files = params.fst_one_vs_all ? ( (params.tajimas_d || params.pi_val) ? l_html_files.combine(l_f_html_files, by:0):l_f_html_files):l_html_files
        
        l_html_files.view()
        */
}
