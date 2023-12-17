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

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK          } from '../subworkflows/local/input_check'
include { FILTER_VCF           } from '../subworkflows/local/filter_vcf'
include { FILTER_BED           } from '../subworkflows/local/filter_bed'
//include { PREPARE_INDIV_REPORT } from '../subworkflows/local/prepare_indiv_report'
//include { EXPLORE_GENETIC_STRUCTURE } from '../subworkflows/local/explore_genetic_structure'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { PLINK2_VCF                    } from '../modules/local/plink2/vcf/main'
include { PLINK2_MERGE_BED              } from '../modules/local/plink2/merge_bed/main'
include { GENERATE_COLORS               } from '../modules/local/generate_colors/main'
include { TABIX_BGZIPTABIX              } from '../modules/nf-core/tabix/bgziptabix/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { ADMIXTURE                     } from '../modules/nf-core/admixture/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from '../modules/nf-core/custom/dumpsoftwareversions/main'

include { GAWK_EXTRACT_SAMPLEID; GAWK_EXTRACT_SAMPLEID as REMOVE_SAMPLE_LIST } from '../modules/local/gawk/extract_sampleid/main'
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
        }
        else{
            n1_meta_vcf_idx_map = meta_vcf_idx_map
        }
    }
    //
    // MODULE: GENERATE_COLORS --> if input is vcf, take sample map file else take fam file of plink bed
    //
    GENERATE_COLORS(
        is_vcf ? map_f : INPUT_CHECK.out.variant.map{chrom,bed->bed[2]},
        params.color_map ? Channel.fromPath(params.color_map):[]
    )


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
    }
    /*
    if (params.indiv_summary){
            PREPARE_INDIV_REPORT(
                is_vcf ? n1_meta_vcf_idx_map : n1_meta_bed,
                is_vcf
            )
    }
    if (params.genetic_structure){
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
            //
            // SUBWORKFLOW : EXPLORE_GENETIC_STRUCTURE
            //
            EXPLORE_GENETIC_STRUCTURE(
                n2_meta_bed,
                GENERATE_COLORS.out.color
                    
            )
    }
    */
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
