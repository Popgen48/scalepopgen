import sys

# this function combine the text file and generate the reports output by plink --sample-counts


def combine_indiv_reports(is_vcf, plink_sample_summary_out):
    is_vcf = False if is_vcf == "false" else True
    sample_stat_dict = {}
    dest = open("genomewide_indiv_report.tsv", "w")
    dest_header = [
        "SAMPLE_ID",
        "HOM_REF_CT",
        "HOM_ALT_SNP_CT",
        "HET_SNP_CT",
        "DIPLOID_TRANSITION_CT",
        "DIPLOID_TRANSVERSION_CT",
        "TOTAL_SNP_CT",
    ]
    for file in plink_sample_summary_out:
        header = 0
        with open(file) as source:
            for line in source:
                line = line.rstrip().split()
                if header == 0:
                    header += 1
                else:
                    stat_list = list(map(int, line[1:])) if bool(is_vcf) else list(map(int, line[2:]))
                    sample_chrmwise_snp = sum(stat_list[:3])
                    sample = line[0] if bool(is_vcf) else line[1]
                    if sample not in sample_stat_dict:
                        sample_stat_dict[sample] = [0, 0, 0, 0, 0, 0]
                    for i in range(5):
                        sample_stat_dict[sample][i] += stat_list[i]
                    sample_stat_dict[sample][5] += sample_chrmwise_snp
    dest.write("\t".join(dest_header) + "\n")
    for sample in sample_stat_dict:
        dest.write(
            sample + "\t" + "\t".join(list(map(str, sample_stat_dict[sample]))) + "\n"
        )
    dest.close()


if __name__ == "__main__":
    combine_indiv_reports(sys.argv[1],sys.argv[2:])
