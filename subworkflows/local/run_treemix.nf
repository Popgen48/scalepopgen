/* 
* run treemix analysis with bootstrapping
*/

include { PYTHON_CONVERT_VCF2TREEMIX                            } from "../../modules/local/python/convert/vcf2treemix/main"
include { GAWK_MERGE_TREEMIX_INPUTS                             } from "../../modules/local/gawk/merge_treemix_inputs/main"
include { TREEMIX as TREEMIX_RUN_M0                             } from "../../modules/local/treeemix/main"
include { TREEMIX as TREEMIX_RUN_M0_BOOTSTRAP                   } from "../../modules/local/treeemix/main"
include { TREEMIX as TREEMIX_ADD_MIG                            } from "../../modules/local/treeemix/main"
include { RSCRIPT_PLOT_TREE as RSCRIPT_PLOT_TREE_M0             } from "../../modules/local/rscript/plot_tree/main"
include { RSCRIPT_PLOT_TREE as RSCRIPT_PLOT_TREE_M0_BOOTSTRAP   } from "../../modules/local/rscript/plot_tree/main"
include { RSCRIPT_PLOT_TREE as RSCRIPT_PLOT_TREE_ADD_MIG        } from "../../modules/local/rscript/plot_tree/main"
include { RSCRIPT_OPTM                                          } from "../../modules/local/rscript/optm/main"
include { PHYLIP_CONSENSE                                       } from "../../modules/local/phylip/consense/main"
include { PYTHON_PDF2IMAGE                                      } from "../../modules/local/python/pdf2image/main"


def generate_random_num(num_bootstrap, upper_limit, set_random_seed){
	random_num_tuple = []
	int num_boot = num_bootstrap
	int upper_lim = upper_limit
        if (set_random_seed == true){
            while (random_num_tuple.size()<num_bootstrap){
                    int j = (Math.abs(new Random().nextInt() % upper_limit) + 1)
                    if(!(random_num_tuple.contains(j))){
                            random_num_tuple.add(j)
                    }
            }
        }
        else{
            int i = 0
            while(i<num_boot){
                i+=1
                random_num_tuple.add("it_"+i.toString())
            }
        }
	return random_num_tuple
}

def generate_random_num_m(num_it, upper_limit){
    random_num_tuple = []
    int i=0
    while(i<num_it){
        int j = (Math.abs(new Random().nextInt() % upper_limit) + 1)
        if (j > 100){
            i+=1
            random_num_tuple.add([i,j])
        }
    }
    return random_num_tuple
}



workflow RUN_TREEMIX {
    take:
        chrom_vcf_idx_map
        is_vcf
    main:
        vcf = chrom_vcf_idx_map.map{ chrom, vcf, idx, mp -> vcf}
        mp = chrom_vcf_idx_map.map{ chrom, vcf, idx, mp -> mp }.unique()
        //
        // MODULE : PYTHON_CONVERT_VCF2TREEMIX
        //
        PYTHON_CONVERT_VCF2TREEMIX(
            chrom_vcf_idx_map,
            is_vcf
        )

        if (is_vcf == true){
                //
                // MODULE: GAWK_MERGE_TREEMIX_INPUTS
                //

                GAWK_MERGE_TREEMIX_INPUTS(  
                    PYTHON_CONVERT_VCF2TREEMIX.out.treemix_in.collect()
                )
        }
        
        treemix_in = is_vcf == true ? GAWK_MERGE_TREEMIX_INPUTS.out.gz : PYTHON_CONVERT_VCF2TREEMIX.out.treemix_in

        //
        // MODULE: TREEMIX_RUN_DEFAULT
        // 
        TREEMIX_RUN_M0(
                treemix_in.combine([1234]).combine([0]).combine([1]),
                Channel.value("default")
        )
        //
        // MODULE: RSCRIPT_PLOT_TREE
        // 
        RSCRIPT_PLOT_TREE_M0(
            TREEMIX_RUN_M0.out.treeout,
            TREEMIX_RUN_M0.out.vertices,
            TREEMIX_RUN_M0.out.edges,
            TREEMIX_RUN_M0.out.covse,
            Channel.value("default")
        )

        PYTHON_PDF2IMAGE(
            RSCRIPT_PLOT_TREE_M0.out.pdf
        )
        
        jpg = PYTHON_PDF2IMAGE.out.jpg

        if(params.n_bootstrap > 0){
            random_num_tuple = generate_random_num(params.n_bootstrap, 34680, params.set_random_seed)
            ti_rn = treemix_in.combine(random_num_tuple)
            //
            // MODULE: TREEMIX_RUN_BOOTSTRAP
            //
            TREEMIX_RUN_M0_BOOTSTRAP(
                ti_rn.combine([0]).combine([1]),
                Channel.value("bootstrap")
            )
            
            //
            // MODULE: RSCRIPT_PLOT_TREE_BOOTSTRAP
            //
            RSCRIPT_PLOT_TREE_M0_BOOTSTRAP(
                TREEMIX_RUN_M0_BOOTSTRAP.out.treeout,
                TREEMIX_RUN_M0_BOOTSTRAP.out.vertices,
                TREEMIX_RUN_M0_BOOTSTRAP.out.edges,
                TREEMIX_RUN_M0_BOOTSTRAP.out.covse,
                Channel.value("bootstrap")
            )
            //
            //MODULE: PHYLIP_CONSENSE
            //
            PHYLIP_CONSENSE(
                TREEMIX_RUN_M0_BOOTSTRAP.out.treeout.collect()
            )
        }
        if(params.n_mig > 0){
            m_val = Channel.from(1..params.n_mig)
            i_val = Channel.from(1..params.n_iter)
            
            if(params.set_random_seed == false){
                ti_rn_m_i = treemix_in.combine([1234]).combine(m_val).combine(i_val)
            }
            else{
                random_num_tuple_m = generate_random_num_m(params.n_iter, params.rand_k_snps==true ? params.k_snps:34680)
                i_s = i_val.combine(random_num_tuple_m, by:0)
                ti_rn_m_i = treemix_in.combine(i_s).combine(m_val).map{inp,i,rn,m->tuple(inp,rn,m,i)}
            }
            //
            //MODULE: TREEMIX_ADD_MIG
            //
            TREEMIX_ADD_MIG(
                ti_rn_m_i,
                Channel.value("add_mig")
            )
            //
            //MODULE: RSCRIPT_PLOT_TREE_ADD_MIG
            //
            RSCRIPT_PLOT_TREE_ADD_MIG(
                TREEMIX_ADD_MIG.out.treeout,
                TREEMIX_ADD_MIG.out.vertices,
                TREEMIX_ADD_MIG.out.edges,
                TREEMIX_ADD_MIG.out.covse,
                Channel.value("add_mig")
            )
            //
            //MODULE: RSCRIPT_OPTM
            //
            RSCRIPT_OPTM(
                TREEMIX_ADD_MIG.out.llik.collect(),
                TREEMIX_ADD_MIG.out.modelcov.collect(),
                TREEMIX_ADD_MIG.out.cov.collect()
            )
        }
    emit:
        jpg
}
