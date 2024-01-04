/* 
* run treemix analysis with bootstrapping
*/

include { PYTHON_CONVERT_VCF2TREEMIX } from "../../modules/local/python/convert/vcf2treemix/main"
//include { MERGE_TREEMIX_INPUTS } from "../modules/treemix/merge_treemix_inputs.nf"
//include { PREPARE_POP_FILE } from "../modules/treemix/prepare_pop_file.nf"
//include { RUN_TREEMIX_DEFAULT } from "../modules/treemix/run_treemix_default"
//include { RUN_TREEMIX_WITH_BOOTSTRAP } from "../modules/treemix/run_treemix_with_bootstrap"
//include { RUN_CONSENSE } from "../modules/phylip/run_consense"
//include { ADD_MIGRATION_EDGES } from "../modules/treemix/add_migration_edges"
//include { EST_OPT_MIGRATION_EDGE } from "../modules/treemix/est_opt_migration_edge"


def generate_random_num(num_bootstrap, upper_limit){
	random_num_tuple = []
	int num_boot = num_bootstrap
	int upper_lim = upper_limit
	while (random_num_tuple.size()<num_bootstrap){
    		int j = (Math.abs(new Random().nextInt() % upper_limit) + 1)
    		if(!(random_num_tuple.contains(j))){
        		random_num_tuple.add(j)
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
        //pop_file = PREPARE_POP_FILE(mp)
        //
        //MODULE : PYTHON_CONVERT_VCF2TREEMIX
        //
        PYTHON_CONVERT_VCF2TREEMIX(
            chrom_vcf_idx_map,
            is_vcf
        )
        //chrwise_treemix_input = ( chrom_vcf_idx_map ).collect()
        /*
        genomewide_treemix_input = MERGE_TREEMIX_INPUTS(chrwise_treemix_input)
        treemixin_mp = genomewide_treemix_input.combine(pop_file)
        RUN_TREEMIX_DEFAULT(treemixin_mp)
        if ( params.n_bootstrap > 0 ){
            random_num_tuple = generate_random_num(params.n_bootstrap, params.upper_limit)
            treemix_input_num_t = treemixin_mp.combine(random_num_tuple)
            bootstrapped_trees = RUN_TREEMIX_WITH_BOOTSTRAP(treemix_input_num_t)
            RUN_CONSENSE(bootstrapped_trees.treeout.collect())
        }
        if (params.starting_m_value > 0){
            m_value = Channel.from(params.starting_m_value..params.ending_m_value)
            m_treemixin_mp = m_value.combine(treemixin_mp)
            itr_v = Channel.from(1..params.n_iter)
            it_m_treemixin_mp = itr_v.combine(m_treemixin_mp)
            mig_out = ADD_MIGRATION_EDGES( it_m_treemixin_mp )
            EST_OPT_MIGRATION_EDGE( mig_out.llik.collect(), mig_out.modelcov.collect(), mig_out.cov.collect())
        }
        */
}
