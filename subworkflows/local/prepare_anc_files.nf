/* 
* workflow to estimate ancestral alleles from vcf file
*/

include { PYTHON_CREATE_ESTSFS_INPUT } from '../../modules/local/python/create/estsfs_input/main'
include { ESTSFS                     } from '../../modules/nf-core/estsfs/main'
include { GAWK_CREATE_ANC_FILES      } from '../../modules/local/gawk/create_anc_files/main'


workflow PREPARE_ANC_FILES{
    take:
        chrom_vcf_idx_map
    main:
        if(!params.anc_alleles_map){
        //
        //MODULE: PYTHON_CREATE_ESTSFS_INPUT
        //
        PYTHON_CREATE_ESTSFS_INPUT(
            chrom_vcf_idx_map
        )
        //
        //MODULE: ESTSFS
        //
        ESTSFS(
           PYTHON_CREATE_ESTSFS_INPUT.out.config.combine(PYTHON_CREATE_ESTSFS_INPUT.out.data,by:0).combine(PYTHON_CREATE_ESTSFS_INPUT.out.seed,by:0)
        )
        //
        //MODULE: GAWK_CREATE_ANC_FILES
        //
        GAWK_CREATE_ANC_FILES(
            PYTHON_CREATE_ESTSFS_INPUT.out.map.join(ESTSFS.out.pvalues_out)
        )
        

        chrom_vcf_idx_map_anc = chrom_vcf_idx_map.join(GAWK_CREATE_ANC_FILES.out.anc)
        
        
        }
        
        else{
            Channel
                .fromPath(params.anc_alleles_map)
                .splitCsv(header=true)
                .map{ row->if(!file(row.anc).exists()){exit 1,'ERROR: input anc file does not exist-> ${row.anc}'}else{tuple([id:row.id],path(row.anc))} }
                .set{ chrom_anc }
            chrom_vcf_idx_map_anc = chrom_vcf_idx_map.join(chrom_anc)
        }

    emit:
        n0_meta_vcf_idx_map_anc = chrom_vcf_idx_map_anc

}
