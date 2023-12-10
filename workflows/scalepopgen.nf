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
include { INPUT_CHECK } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { VCFTOOLS                    } from '../modules/nf-core/vcftools/main'
include { VCFTOOLS_CONCAT             } from '../modules/local/vcftools/concat/main'
include { VCFTOOLS_KEEP               } from '../modules/local/vcftools/keep/main'
include { FILTER_SAMPLES              } from '../modules/local/plink2/filter_samples/main'
include { PREPARE_NEW_MAP             } from '../modules/local/prepare_new_map/main'
include { VCFTOOLS_REMOVE             } from '../modules/local/vcftools/remove/main'
include { VCFTOOLS_FILTER_SITES       } from '../modules/local/vcftools/filter_sites/main'
include { FILTER_SNPS                 } from '../modules/local/plink2/filter_snps/main'
include { PLINK_VCF                   } from '../modules/nf-core/plink/vcf/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { ADMIXTURE                   } from '../modules/nf-core/admixture/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { GENERATE_COLORS             } from '../modules/local/generate_colors/main'

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
        sampleinfo = Channel.fromPath( params.sample_map )
        map_f= sampleinfo.map{ sampleinfo -> if(!file(sampleinfo).exists() ){ exit 1, "ERROR: file does not exit -> ${sampleinfo}" }else{sampleinfo}}
        //combine vcf and map file
        meta_vcf_idx_map = INPUT_CHECK.out.variant.combine(map_f)
    }
    //
    // MODULE: GENERATE_COLORS
    //
    GENERATE_COLORS(
        is_vcf ? sampleinfo : INPUT_CHECK.out.variant.map{chrom,bed->bed[2]},
        params.color_map ? Channel.fromPath(params.color_map):[]
    )

    if (is_vcf){

        if( params.apply_indi_filters ){
        
            o_map = meta_vcf_idx_map.map{meta, vcf, idx, map_f -> map_f}.unique()

            /* --> king_cutoff and missingness filter should be based on the entire genome therefore vcf file should be concatenated first and then 
                   supply to plink. From plink module, the list of individuals to be kept is piped out and supply to keep indi module. This module will
                   then extract these sets of individuals from each chromosome file separately. Note that if custom individuals to be removed are also
                    supplied then this will be considered in extract_unrelated_sample_list module as well. 
            */      
    
            if( params.king_cutoff > 0 || params.mind > 0 ){


                vcflist = meta_vcf_idx_map.map{meta, vcf, idx, map_f -> vcf}.collect()

                //
                // MODULE: CONCAT_VCF
                //

                VCFTOOLS_CONCAT(
                    vcflist,
                    Channel.value("filtering")
                )

                //
                // MODULE: FILTER_SAMPLES
                //
                FILTER_SAMPLES( 
                    VCFTOOLS_CONCAT.out.concatenatedvcf,
                    is_vcf
                )

                //
                // MODULE: VCFTOOLS_KEEP
                //
                VCFTOOLS_KEEP(
                    meta_vcf_idx_map.combine(FILTER_SAMPLES.out.keep_indi_list)
                )
                
                //
                // MODULE: PREPARE_NEW_MAP
                //

                PREPARE_NEW_MAP(
                    o_map,
                    FILTER_SAMPLES.out.keep_indi_list
                )
            
                n0_meta_vcf_idx_map = VCFTOOLS_KEEP.out.f_meta_vcf.combine(PREPARE_NEW_MAP.out.n_map).map{meta, vcf, n_map->tuple(meta, vcf, [], n_map)}
            }

            /*
                if only the individuals to be removed are supplied then there is no need to concat the file. 
            
            */
            else{
    
                rmindilist = Channel.fromPath( params.rem_indi )
                ril = rmindilist.map{ rmindilist -> if(!file(rmindilist).exists() ){ exit 1,"ERROR: file does not exit -> ${rmindilist}" }else{rmindilist} }
                meta_vcf = meta_vcf_idx_map.map{meta, vcf, idx, map -> tuple(meta,vcf)}
                //
                // MODULE: VCFTOOLS_REMOVE
                //
                VCFTOOLS_REMOVE( 
                    meta_vcf.combine(ril)
                )
                //
                // MODULE: PREPARE_NEW_MAP
                //
                PREPARE_NEW_MAP(
                    o_map,
                    ril
                )
                n0_meta_vcf_idx_map = VCFTOOLS_REMOVE.out.f_meta_vcf.combine(PREPARE_NEW_MAP.out.n_map).map{meta, vcf, n_map->tuple(meta, vcf, [], n_map)}
            }
        }
        else{
            n0_meta_vcf_idx_map = meta_vcf_idx_map
        }
        if(params.apply_snp_filters){
                n_map = n0_meta_vcf_idx_map.map{meta, vcf, idx, map_f -> map_f}.unique()
                meta_vcf = n0_meta_vcf_idx_map.map{meta, vcf, idx, map_f -> tuple(meta, vcf)}    
                //
                // MODULE: FILTER_SITES
                //
                VCFTOOLS_FILTER_SITES(
                    meta_vcf
                )
                n1_meta_vcf_idx_map = VCFTOOLS_FILTER_SITES.out.s_meta_vcf.combine(n_map).map{meta, vcf, n_map -> tuple(meta, vcf, [], n_map)}
        }
        else{
            n1_meta_vcf_idx_map = n0_meta_vcf_idx_map
        }
    }

    else{
        if( params.apply_indi_filters){
            //
            //MODULE: FILTER_SAMPLES
            //
            FILTER_SAMPLES(
                INPUT_CHECK.out.variant,
                is_vcf
            )
            n0_meta_bed = FILTER_SAMPLES.out.n1_meta_bed
        }
        else{
                n0_meta_bed = INPUT_CHECK.out.variant
        }
        if ( params.apply_snp_filters ){
            //
            //MODULE: FILTER_SNPS
            //
            FILTER_SNPS(
                n0_meta_bed
            )
            n1_meta_bed = FILTER_SNPS.out.n1_meta_bed
            n1_meta_bed.view()
        }
        else{
            n1_meta_bed = n0_meta_bed
            n1_meta_bed.view()
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
