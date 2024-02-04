/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { validateParameters; paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

//WorkflowScalepopgen.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLINK2_VCF                    } from '../modules/local/plink2/vcf/main'
include { PLINK2_MERGE_BED              } from '../modules/local/plink2/merge_bed/main'
include { PLINK2_REMOVE_CUSTOM_INDI     } from '../modules/local/plink2/remove_custom_indi/main'
include { PLINK2_INDEP_PAIRWISE         } from '../modules/local/plink2/indep-pairwise/main'
include { GAWK_GENERATE_COLORS          } from '../modules/local/gawk/generate_colors/main'
include { PLINK2_CONVERT_BED_TO_VCF     } from '../modules/local/plink2/convert_bed_to_vcf/main'
include { GAWK_MAKE_SAMPLE_MAP          } from '../modules/local/gawk/make_sample_map/main'
include { GAWK_ADD_CONTIG_LENGTH        } from '../modules/local/gawk/add_contig_length/main'
include { GAWK_EXTRACT_SAMPLEID; GAWK_EXTRACT_SAMPLEID as REMOVE_SAMPLE_LIST } from '../modules/local/gawk/extract_sampleid/main'
//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK          } from '../subworkflows/local/input_check'
include { FILTER_VCF           } from '../subworkflows/local/filter_vcf'
include { FILTER_BED           } from '../subworkflows/local/filter_bed'
include { PREPARE_INDIV_REPORT } from '../subworkflows/local/prepare_indiv_report'
include { RUN_PCA              } from '../subworkflows/local/run_pca'
include { RUN_ADMIXTURE        } from '../subworkflows/local/run_admixture'
include { CALC_FST             } from '../subworkflows/local/calc_fst'
include { CALC_1_MIN_IBS_DIST  } from '../subworkflows/local/calc_1_min_ibs_dist'
include { RUN_TREEMIX          } from '../subworkflows/local/run_treemix'
include { RUN_VCFTOOLS         } from '../subworkflows/local/run_vcftools'
include { PREPARE_ANC_FILES    } from '../subworkflows/local/prepare_anc_files'
include { RUN_SWEEPFINDER2     } from '../subworkflows/local/run_sweepfinder2'
include { PHASE_GENOTYPES      } from '../subworkflows/local/phase_genotypes'
include { RUN_SELSCAN          } from '../subworkflows/local/run_selscan'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { TABIX_BGZIPTABIX              } from '../modules/nf-core/tabix/bgziptabix/main'
include { TABIX_TABIX                   } from '../modules/nf-core/tabix/tabix/main'
include { ADMIXTURE                     } from '../modules/nf-core/admixture/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { BCFTOOLS_SPLIT                } from '../modules/nf-core/bcftools/split/main'
include { MULTIQC; MULTIQC as MULTIQC_GENETIC_STRUCTURE                      } from '../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow SCALEPOPGEN {

    ch_versions = Channel.empty()

    is_vcf = true

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        file(params.input)
    )
    
    // if input csv file ends with "plink.csv" set vcf to false
    if (params.input.endsWith(".p.csv")){
        is_vcf = false
    }
    if (is_vcf){
        //read sample map file 
        map_f = Channel.fromPath( params.sample_map, checkIfExists: true )

        //combine vcf and map file
        meta_vcf_idx_map = INPUT_CHECK.out.variant.combine(map_f)


        if(params.apply_snp_filters || params.apply_indi_filters){

            //
            //SUBWORKFLOW: FILTER_VCF
            //
            FILTER_VCF(
                meta_vcf_idx_map,
                is_vcf
            )
            n1_meta_vcf_idx_map = FILTER_VCF.out.n1_meta_vcf_idx_map

            ch_versions = ch_versions.mix(FILTER_VCF.out.versions)
        }
        else{
            n1_meta_vcf_idx_map = meta_vcf_idx_map
        }
    }
    //
    // MODULE: GENERATE_COLORS --> if input is vcf, take sample map file else take fam file of plink bed
    //
    GAWK_GENERATE_COLORS(
        is_vcf ? map_f : INPUT_CHECK.out.variant.map{chrom,bed->bed[2]},
        params.color_map ? Channel.fromPath(params.color_map):[]
    )

    ch_versions = ch_versions.mix(GAWK_GENERATE_COLORS.out.versions)

    if(!is_vcf){
        if(params.apply_snp_filters || params.apply_indi_filters){
        //
        // SUBWORKFLOW: FILTER_BED
        //
            FILTER_BED(
                INPUT_CHECK.out.variant,
                is_vcf
            )
            n1_meta_bed = FILTER_BED.out.n1_meta_bed
        }
        else{
            n1_meta_bed = INPUT_CHECK.out.variant
        }
        if(params.treemix || params.ihs || params.xp_ehh || params.sweepfinder2 || params.tajimas_d || params.fst_one_vs_all || params.pi_val || params.pairwise_local_fst){
            //
            // MODULE: PLINK2_CONVERT_BED_TO_VCF
            //
            PLINK2_CONVERT_BED_TO_VCF(
                n1_meta_bed
            )
            if(params.chrom_length_map){
                clm = Channel.fromPath( params.chrom_length_map, checkIfExists: true )
                //
                // MODULE: GAWK_ADD_CONTIG_LENGTH
                //
                GAWK_ADD_CONTIG_LENGTH(
                    PLINK2_CONVERT_BED_TO_VCF.out.vcf,
                    clm
                )
            }
            //
            // MODULE: TABIX_BGZIPTABIX
            //
            TABIX_BGZIPTABIX(
                params.chrom_length_map ? GAWK_ADD_CONTIG_LENGTH.out.vcf : PLINK2_CONVERT_BED_TO_VCF.out.vcf
            )
            //
            // MODULE: GAWK_MAKE_SAMPLE_MAP
            //
            GAWK_MAKE_SAMPLE_MAP(
                n1_meta_bed.map{meta,bed->bed[2]}
            )

            n1_meta_vcf_idx_map = TABIX_BGZIPTABIX.out.gz_tbi.combine(GAWK_MAKE_SAMPLE_MAP.out.map)

        }
    }
    
    g_ch_multiqc_files = Channel.empty().ifEmpty([])

    if (params.genetic_structure || params.indiv_summary){


            if(is_vcf){
                //
                //MODULE: PLINK2_VCF
                //
                PLINK2_VCF(
                    n1_meta_vcf_idx_map.map{meta, vcf, idx, map->tuple(meta,vcf)}
                )
                //PLINK2_VCF.out.bed.view()
                
                //
                //MODULE: PLINK2_MERGE_BED
                //
                PLINK2_MERGE_BED(
                    PLINK2_VCF.out.bed.collect(),
                    n1_meta_vcf_idx_map.map{meta, vcf, idx, map->map}.unique()
                )
                n2_meta_bed = PLINK2_MERGE_BED.out.bed
                }
            else{
                n2_meta_bed = n1_meta_bed
            }
            if (params.indiv_summary){
                    //
                    //SUBWORKFLOW: PREPARE_INDIV_REPORT
                    //
                    PREPARE_INDIV_REPORT(
                        n2_meta_bed,
                        GAWK_GENERATE_COLORS.out.color
                    )
                g_ch_multiqc_files = g_ch_multiqc_files.combine(PREPARE_INDIV_REPORT.out.ch_multiqc_files)
            }
            if ( params.rem_indi_structure ){
                    indi_list = Channel.fromPath( params.rem_indi_structure, checkIfExists: true)
                    //
                    //MODULE: PLINK2_REMOVE_CUSTOM_INDI
                    //
                    PLINK2_REMOVE_CUSTOM_INDI(
                        n2_meta_bed, 
                        indi_list 
                    )
                    n3_bed = PLINK2_REMOVE_CUSTOM_INDI.out.bed
            }
            
            else{
                    n3_bed = n2_meta_bed
            }
            if ( params.ld_filt ){
                    //
                    //MODULE: PLINK2_LD_FILTERS
                    //
                    PLINK2_INDEP_PAIRWISE(
                        n3_bed
                    )
                    n4_bed = PLINK2_INDEP_PAIRWISE.out.bed
            }
            else{
                    n4_bed = n3_bed
            }
            if(params.smartpca){
                //
                // SUBWORKFLOW : RUN_PCA
                //
                RUN_PCA(
                    n4_bed,
                    GAWK_GENERATE_COLORS.out.color
                )
                g_ch_multiqc_files = g_ch_multiqc_files.combine(RUN_PCA.out.html)
            }
            if(params.admixture){
                //
                // SUBWORKFLOW : RUN_ADMIXTURE
                //
                RUN_ADMIXTURE(
                    n4_bed,
                    GAWK_GENERATE_COLORS.out.color
                )
                g_ch_multiqc_files = g_ch_multiqc_files.combine(RUN_ADMIXTURE.out.qmat_html)
                g_ch_multiqc_files = g_ch_multiqc_files.combine(RUN_ADMIXTURE.out.cv_html)
            }
            if(params.pairwise_global_fst){
                //
                // SUBWORKFLOW : CALC_FST
                //
                CALC_FST(
                    n4_bed,
                    GAWK_GENERATE_COLORS.out.color
                )
                g_ch_multiqc_files = g_ch_multiqc_files.combine(CALC_FST.out.html)
            }
            if(params.ibs_dist){
                //
                // SUBWORKFLOW : CALC_1_MIN_IBS_DIST
                //
                CALC_1_MIN_IBS_DIST(
                    n4_bed,
                    GAWK_GENERATE_COLORS.out.color
                )
                g_ch_multiqc_files = g_ch_multiqc_files.combine(CALC_1_MIN_IBS_DIST.out.html)
            }
            //
            //MODULE: MULTIQC_GENETIC_STRUCTURE
            //
    }
    if(params.treemix){
        //
        // SUBWORKFLOW : RUN_TREEMIX
        //
        RUN_TREEMIX(
            n1_meta_vcf_idx_map,
            is_vcf
        )
        g_ch_multiqc_files = g_ch_multiqc_files.combine(RUN_TREEMIX.out.jpg)
        g_ch_multiqc_files = g_ch_multiqc_files.combine(RUN_TREEMIX.out.jpg_m)
    }

    mqc_genetic_struct_config = Channel.fromPath(params.multiqc_report_yml)
    //
    //MODULE: MULTIQC_GENETIC_STRUCTURE
    //
    MULTIQC_GENETIC_STRUCTURE(
        g_ch_multiqc_files,
        mqc_genetic_struct_config,
        [],
        []
    )

    if(params.pairwise_local_fst || params.tajimas_d || params.pi_val || params.fst_one_vs_all){
        //
        // SUBWORKFLOW : RUN_VCFTOOLS
        // 
        RUN_VCFTOOLS(
            n1_meta_vcf_idx_map
        )
    }

    if( params.sweepfinder2 || params.ihs || params.xp_ehh ){
        if( is_vcf ){
            n2_meta_vcf_idx_map = n1_meta_vcf_idx_map
        }
        else{
            map_f = n1_meta_vcf_idx_map.map{meta,vcf,idx,map->map}
            //
            //MODULE: BCFTOOLS_SPLIT
            //
            BCFTOOLS_SPLIT(
                n1_meta_vcf_idx_map.map{meta,vcf,idx,map->tuple(meta,vcf,idx)}
            )

            meta_vcf = BCFTOOLS_SPLIT.out.split_vcf.map{meta,vcf->vcf}.flatten().map{vcf->tuple([id:vcf.getName().minus(".vcf.gz").split("\\.")[-1]], vcf)}
            //
            //MODULE: TABIX_TABIX
            //
            TABIX_TABIX(
                meta_vcf
            )

            n2_meta_vcf_idx_map = meta_vcf.join(TABIX_TABIX.out.tbi).combine(map_f)
        }
                
        if ( params.sweepfinder2 ){
            if( params.est_anc_alleles ){
                //
                // SUBWORKFLOW : PREPARE_ANC_FILES
                //
                PREPARE_ANC_FILES(
                    n2_meta_vcf_idx_map
                )
                //n1_meta_vcf_idx_map_anc = PREPARE_ANC_FILES.out.n0_meta_vcf_idx_map_anc
            }
            //
            // SUBWORKFLOW : RUN_SWEEPFINDER2
            //
            RUN_SWEEPFINDER2(
                params.est_anc_alleles ? PREPARE_ANC_FILES.out.n0_meta_vcf_idx_map_anc : n2_meta_vcf_idx_map.combine([null])
            )
            }
        if( params.ihs || params.xp_ehh ){
                //
                //SUBWORKFLOW : PHASE_GENOTYPES
                //
                PHASE_GENOTYPES(
                    n2_meta_vcf_idx_map
                )

                //
                //SUBWORKFLOW : RUN_SELSCAN
                //
                RUN_SELSCAN(
                    PHASE_GENOTYPES.out.n3_meta_vcf_idx_map
                )

            }
    }
    /*
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    // TODO: OPTIONAL, you can use nf-validation plugin to create an input channel from the samplesheet with Channel.fromSamplesheet("input")
    // See the documentation https://nextflow-io.github.io/nf-validation/samplesheets/fromSamplesheet/
    // ! There is currently no tooling to help you write a sample sheet schema


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowScalepopgen.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowScalepopgen.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
    */
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
