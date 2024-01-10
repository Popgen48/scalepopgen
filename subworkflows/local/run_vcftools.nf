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
/*
include { GENERATE_INTERACTIVE_MANHATTAN_PLOT as MANHATTAN_TAJIMAS_D } from '../modules/selection/generate_interactive_manhattan_plot'
include { GENERATE_INTERACTIVE_MANHATTAN_PLOT as MANHATTAN_PI } from '../modules/selection/generate_interactive_manhattan_plot'
include { GENERATE_INTERACTIVE_MANHATTAN_PLOT as MANHATTAN_FST } from '../modules/selection/generate_interactive_manhattan_plot'
*/


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
        }
        if( params.pi_val ){
            //
            //MODULE: VCFTOOLS_PI
            //
            VCFTOOLS_PI(
                n0_chrom_vcf_popid.map{chrom,vcf,popid->tuple(chrom,vcf,popid,[])},
                Channel.value("pi_val")
            )
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
        }
        
        /*

        
        //each sample id file should be combine with each vcf file

        n4_chrom_vcf_popid = n4_chrom_vcf.combine(pop_idfile)

        //following module calculates tajima's d for each chromosome for each pop
        

        if( params.tajimas_d ){

            CALC_TAJIMA_D( n4_chrom_vcf_popid )

            v1_manhatin = Channel.value('tajimas_d')

            v1_windowsize = Channel.value(params.tajimasd_window_size)

            MANHATTAN_TAJIMAS_D(
                 CALC_TAJIMA_D.out.tajimasd_out.groupTuple(),
                 v1_manhatin,
                 v1_windowsize
                )
        
        }

        // following module calculates pi for each chromosome for each pop

        if ( params.pi ){

            CALC_PI( n4_chrom_vcf_popid )

            v2_manhatin = Channel.value('nucl_diversity_pi')

            v2_windowsize = params.pi_window_size > 0 ? Channel.value(params.pi_window_size) : Channel.value(1)

            MANHATTAN_PI(
                CALC_PI.out.pi_out.groupTuple(),
                v2_manhatin,
                v2_windowsize
            )
        }

        
        if ( params.pairwise_fst ){
               
                // prepare channel for the pairwise fst                


            pop_idfile_collect = pop_idfile.collect()
            

            pop1_pop2 = PREPARE_DIFFPOP_T(pop_idfile_collect).unique()


             n4_chrom_vcf_pop1_pop2 = n4_chrom_vcf.combine(pop1_pop2)
            
            CALC_WFST( n4_chrom_vcf_pop1_pop2 )
            
        }
        if( params.single_vs_all_fst ){
                
                pop1_allsample = pop_idfile.combine(SPLIT_MAP_FOR_VCFTOOLS.out.iss)

                n4_chrom_vcf_pop1_allsample = n4_chrom_vcf.combine(pop1_allsample)

                CALC_WFST_ONE_VS_REMAINING(n4_chrom_vcf_pop1_allsample)
            
                v3_manhatin = Channel.value('fst_values')

                v3_windowsize = params.fst_window_size > 0 ? Channel.value(params.fst_window_size) : Channel.value(1)

                MANHATTAN_FST(
                    CALC_WFST_ONE_VS_REMAINING.out.pairwise_fst_out.groupTuple(),
                    v3_manhatin,
                    v3_windowsize
                )

            }
    */
}
