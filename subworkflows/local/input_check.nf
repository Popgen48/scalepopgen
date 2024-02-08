//
// Check input samplesheet and get read channels
//


workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    Channel
        .fromPath(samplesheet)
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { variant }

    emit:
    variant                                     // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    def vcf_meta = []
    // if the length is 3, the row contains information about vcf files splitted by chromosome
    if (row.size() == 3 ){
        meta.id         = row.chrom
        /*
        if (!file(row.vcf).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> vcf file does not exist!\n${row.vcf}"
        }
        if (!file(row.vcf_idx).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> vcf index file does not exist!\n${row.vcf_idx}"
        }
        */
        vcf_meta = [ meta, file(row.vcf), file(row.vcf_idx)  ]
    }
    else{
        // if the length is 4, the row contains information about plink bim, bed and fam file
        if (row.size() == 4 ){
            meta.id         = row.prefix
            if (!file(row.bed).exists()) {
                exit 1, "ERROR: Please check input samplesheet -> the bed file does not exist!\n${row.bed}"
            }
            if (!file(row.bim).exists()) {
                exit 1, "ERROR: Please check input samplesheet -> the bim file does not exist!\n${row.bim}"
            }
            if (!file(row.fam).exists()) {
                exit 1, "ERROR: Please check input samplesheet -> the fam file does not exist!\n${row.fam}"
            }
            vcf_meta = [ meta, [file(row.bed), file(row.bim), file(row.fam)]  ]
        }
        else{
            println(row.size())
            exit 1, "ERROR: Please check input csv samplesheet, it does not have 3-column or 4-column format"
        }
    }
    return vcf_meta
}
