/* 
* workflow to carry out signature of selection using sweepfinder2
*/

include { PYTHON_SPLIT_MAP as SPLIT_MAP_SWEEPFINDER2 } from '../../modules/local/python/split_map/main'
include { GAWK_MERGE_FREQ_FILES                      } from '../../modules/local/gawk/merge_freq_files/main'
include { PYTHON_CREATE_SWEEPFINDER_INPUT            } from '../../modules/local/python/create/sweepfinder_input/main'
include { SWEEPFINDER2; SWEEPFINDER2 as SWEEPFINDER2_COMPUTE_EMPIRICAL_AFS         } from '../../modules/local/sweepfinder2/main'
include { PYTHON_COLLECT_SELECTION_RESULTS as COLLECT_SWEEPFINDER2                 } from '../../modules/local/python/collect/selection_results/main'
include { PYTHON_PLOT_SELECTION_RESULTS as PLOT_SWEEPFINDER2                       } from '../../modules/local/python/plot/selection_results/main'


workflow RUN_SWEEPFINDER2{
    take:
        chrom_vcf_idx_map_anc

    main:
        
        selection_plot_yml = Channel.fromPath(params.selection_plot_yml, checkIfExists: true)

        
        // sample map file should be processed separately to split id pop-wise

        map_f = chrom_vcf_idx_map_anc.map{ chrom, vcf, idx, mp, anc -> mp}.unique()

        n1_chrom_vcf_anc = chrom_vcf_idx_map_anc.map{ chrom, vcf, idx, map, anc -> tuple(chrom, vcf, anc) }

        //following module split the map file pop-wise

        //
        // MODULE: SPLIT_MAP_SWEEPFINDER2
        //

        SPLIT_MAP_SWEEPFINDER2(
            map_f,
            Channel.value('sweepfinder2')
        )

        pop_idfile = SPLIT_MAP_SWEEPFINDER2.out.poptxt.flatten()

        //each sample id file should be combine with each vcf file

        n1_chrom_vcf_anc_popid = n1_chrom_vcf_anc.combine(pop_idfile)

        if ( params.recomb_map ){
            //read recombination map file
            Channel
                    .fromPath( params.recomb_map, checkIfExists: true )
                    .splitCsv(sep:",")
                    .map{ chrom, recomb -> if(!file(recomb).exists() ){ exit 1, 'ERROR: input recomb file does not exist  \
                        -> ${recomb}' }else{tuple(chrom, file(recomb))} }
                    .set{ chrom_recomb }

            n1_chrom_vcf_anc_popid_recomb = n1_chrom_vcf_anc_popid.join(chrom_recomb)

        }
        else{
            n1_chrom_vcf_anc_popid_recomb = n1_chrom_vcf_anc_popid.combine([null])
        }

        // prepare sweepfinder input files --> freq file and recomb file
        //
        // MODULE: PYTHON_CREATE_SWEEPFINDER_INPUT
        //

        PYTHON_CREATE_SWEEPFINDER_INPUT(
            n1_chrom_vcf_anc_popid_recomb.map{ chrom, vcf, anc, popid, recomb ->tuple( chrom, vcf, popid, anc ?: [] , recomb ?: [])},
            Channel.value(params.sweepfinder2_model)
        )

        pop_freq_M = PYTHON_CREATE_SWEEPFINDER_INPUT.out.pop_freq.groupTuple()

        if ( params.sweepfinder2_model == "l"  || params.sweepfinder2_model == "lr"){

            //
            // MODULE: GAWK_MERGE_FREQ_FILES
            //
            GAWK_MERGE_FREQ_FILES(
                pop_freq_M
            )

            //
            // MODULE: SWEEPFINDER2_COMPUTE_EMPIRICAL_AFS
            //
            SWEEPFINDER2_COMPUTE_EMPIRICAL_AFS(
                GAWK_MERGE_FREQ_FILES.out.pop_cfreq.map{pop,freq->tuple(pop, freq, [], [])},
                Channel.value("afs")
            )


            pop_freq_afs = PYTHON_CREATE_SWEEPFINDER_INPUT.out.pop_freq.combine(SWEEPFINDER2_COMPUTE_EMPIRICAL_AFS.out.pop_txt, by:0)
        
            pop_freq_afs_recomb = params.sweepfinder2_model == "lr" ? pop_freq_afs.combine(PYTHON_CREATE_SWEEPFINDER_INPUT.out.pop_recomb, by:0):pop_freq_afs.combine([null])
        
        }
        else{
            pop_freq_afs_recomb =pop_freq_M.combine([null]).combine([null])
        }
        //
        // MODULE: SWEEPFINDER2
        //
        SWEEPFINDER2(
            pop_freq_afs_recomb.map{pop, freq, afs, recomb->tuple(pop, freq, afs?:[], recomb?:[])},
            Channel.value(params.sweepfinder2_model)
        )

        //
        // MODULE: COLLECT_SWEEPFINDER2
        //
        COLLECT_SWEEPFINDER2(
                params.chrom_id_map ? SWEEPFINDER2.out.pop_txt.groupTuple().combine(Channel.fromPath(params.chrom_id_map,checkIfExists:true)) : SWEEPFINDER2.out.pop_txt.groupTuple.map{meta,o_files->tuple(meta,o_files,[])},
            Channel.value("sweepfinder2")
        )
        //
        //MODULE: PLOT_SWEEPFINDER2
        // 
        trcs = COLLECT_SWEEPFINDER2.out.cutoff.map{meta,c_file->c_file}.splitCsv(header:true).map{row->tuple([id:row.id],row.cutoff)}.combine(COLLECT_SWEEPFINDER2.out.txt,by:0)

        PLOT_SWEEPFINDER2(
            trcs.combine(selection_plot_yml),
            Channel.value("LR")
        )
}
