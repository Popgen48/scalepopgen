/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Nextflow config file for running full-size tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Defines input files and everything required to run a full size pipeline test.

    Use as follows:
        nextflow run popgen48/scalepopgen -profile test_full,<docker/singularity> --outdir <OUTDIR>

----------------------------------------------------------------------------------------
*/

params {
    config_profile_name        = 'Full test profile for treemix analysis'
    config_profile_description = 'Full test dataset to check pipeline function of treemix on full dataset'

    // Input data for full size test
    // TODO nf-core: Specify the paths to your full test data ( on nf-core/test-datasets or directly in repositories, e.g. SRA)
    // TODO nf-core: Give any required params for the test so that command line flags are not needed
    input = 'https://raw.githubusercontent.com/Popgen48/scalepopgen-test/main/workflow_test_files/test_full/test_input.csv'
    sample_map = 'https://raw.githubusercontent.com/Popgen48/scalepopgen-test/main/workflow_test_files/test_full/sample_map.map'
    rem_indi = 'https://raw.githubusercontent.com/Popgen48/scalepopgen-test/main/workflow_test_files/test_full/samples_to_be_removed.txt'
    apply_indi_filters = true
    treemix = true
}
