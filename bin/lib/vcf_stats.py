# import the necessary modules

import gzip
from pysam import VariantFile
from lib.file_processes import (
    populate_sample_dict,
    write_sample_dict,
    write_pop_dict,
    prepare_sample_pop_dict,
)
from lib.vcf_to_chrom_windows import VcfToChromCords


class VcfStats:
    def __init__(
        self, vcf_in, sample_map, window, step, out_prefix, region, bed_in, bed_ex
    ):
        self.vcf_file_name = vcf_in  # input vcf file
        self.vcf_in = VariantFile(vcf_in)  # method of pysam module
        self.sample_map = sample_map  # map file--> two columns --> sample pop
        self.window_size = window  # window size --> in bp
        self.step_size = step  # step size --> in bp
        self.out_prefix = out_prefix
        self.region = region  # region in format --> chrm:start-end --> 1:10000-20000
        self.bed_in = bed_in  # bed file of the regions to be include
        self.bed_ex = bed_ex  # bed file of the regions to be exclude

        self.sample_pop_dict = {}  # dictionary storing sample as key and pop as value
        self.pop_list = []  # list containing pop name

        self.sample_total_stat = (
            {}
        )  # dictionary storing overall statistics (as opposed to local window based statistics)
        self.pop_total_stat = (
            {}
        )  # same as mentioned in the line above but for population
        self.vcf_samples = list(
            self.vcf_in.header.samples
        )  # read header of the vcf file
        self.params_list = [
            (0, 0),
            (0, 1),
            (1, 1),
            "missing_geno",
            "total_snps",
            "average_depth",
            "average_obs_het",
            "ts",
            "tv",
            "monomorphic",
        ]
        self.geno_dict = {(0, 0): 0, (0, 1): 1, (1, 1): 2}
        self.transitions = [["A", "G"], ["G", "A"], ["C", "T"], ["T", "C"]]

    # following method open the gzipped output files to write
    # dest1 --> sample-wise window-based summary statistics
    # dest2 --> pop-wise window-based summary statistics
    # dest3 --> sample-wise overall summary statistics
    # dest4 --> pop-wise overall summary statistics

    def write_output_headers(self):
        self.dest1 = gzip.open(self.out_prefix + "_sample_local_summary.gz", "wb")
        dest1Header = (
            "chom:start-end"
            + "\t"
            + "\t".join(list(self.sample_pop_dict.keys()))
            + "\n"
        )  # make sure that python version is above 3.8 as the order of key matters
        self.dest1.write(dest1Header.encode())
        self.dest2 = gzip.open(self.out_prefix + "_pop_local_summary.gz", "wb")
        dest2Header = "chom:start-end" + "\t" + "\t".join(list(self.pop_list)) + "\n"
        self.dest2.write(dest2Header.encode())
        self.dest3 = gzip.open(self.out_prefix + "_sample_total_summary.gz", "wb")
        dest3Header = (
            "chom:start-end"
            + "\t"
            + "\t".join(list(self.sample_pop_dict.keys()))
            + "\n"
        )
        self.dest3.write(dest3Header.encode())
        self.dest4 = gzip.open(self.out_prefix + "_pop_total_summary.gz", "wb")
        dest4Header = "chom:start-end" + "\t" + "\t".join(list(self.pop_list)) + "\n"
        self.dest4.write(dest4Header.encode())

    def calc_pop_stats(self):
        for pop in self.pop_local_window_dict:
            samples_per_pop = [
                self.tmp_pop_dict[pop][geno] for geno in list(self.geno_dict.keys())
            ]
            num_pop = max(1, sum(samples_per_pop))
            for geno in list(self.geno_dict.keys()):
                self.pop_local_window_dict[pop][geno] += (
                    self.tmp_pop_dict[pop][geno] / num_pop
                )
                if self.pos > self.previous_window:
                    self.pop_total_dict[pop][geno] += (
                        self.tmp_pop_dict[pop][geno] / num_pop
                    )
            self.pop_local_window_dict[pop]["average_depth"] += (
                self.tmp_pop_dict[pop]["average_depth"] / num_pop
            )
            self.pop_local_window_dict[pop]["missing_geno"] += (
                self.tmp_pop_dict[pop]["missing_geno"] / num_pop
            )
            self.pop_local_window_dict[pop]["average_obs_het"] += (
                self.tmp_pop_dict[pop]["average_obs_het"] / num_pop
            )
            self.pop_local_window_dict[pop]["total_snps"] += 1
            if self.tmp_pop_dict[pop][self.type_snps] > 0:
                self.pop_local_window_dict[pop][self.type_snps] += 1
                if self.pos > self.previous_window:
                    self.pop_total_dict[pop][self.type_snps] += 1
            if self.pos > self.previous_window:
                self.pop_total_dict[pop]["average_depth"] += (
                    self.tmp_pop_dict[pop]["average_depth"] / num_pop
                )
                self.pop_total_dict[pop]["missing_geno"] += (
                    self.tmp_pop_dict[pop]["missing_geno"] / num_pop
                )
                self.pop_total_dict[pop]["average_obs_het"] += (
                    self.tmp_pop_dict[pop]["average_obs_het"] / num_pop
                )
                self.pop_total_dict[pop]["total_snps"] += 1
            if self.minor_allele == "A":
                self.pop_local_window_dict[pop]["maf"] += self.tmp_pop_dict[pop][
                    "A"
                ] / (num_pop * 2)
                if self.pos > self.previous_window:
                    self.pop_total_dict[pop]["maf"] += self.tmp_pop_dict[pop]["A"] / (
                        num_pop * 2
                    )
            if self.minor_allele == "R":
                self.pop_local_window_dict[pop]["maf"] += 1 - self.tmp_pop_dict[pop][
                    "A"
                ] / (num_pop * 2)

    def read_vcf(self):
        for rec in self.vcf_in.fetch(
            self.chrom_read, self.cord_window[0], self.cord_window[1]
        ):
            self.chrom_present = True
            tmp_pop_dict = {}
            total_alternate_allele = 0
            total_alleles = 0
            self.minor_allele = "A"
            if rec.alts != None:
                snps = [rec.ref[0], rec.alts[0]]
                type_snps = ["ts" if snps in self.transitions else "tv"][0]
            else:
                type_snps = "monomorphic"
            for pop in self.pop_list:
                tmp_pop_dict[pop] = {}
                for params in self.params_list:
                    tmp_pop_dict[pop][params] = 0
                tmp_pop_dict[pop]["A"] = 0
            for sample in self.sample_local_window_dict:
                gt = rec.samples[sample]["GT"]
                dp = (
                    rec.samples[sample]["DP"]
                    if rec.samples[sample]["DP"] != None
                    else 0
                )
                if gt in self.params_list:
                    tmp_pop_dict[self.sample_pop_dict[sample]]["average_depth"] += int(
                        dp
                    )
                    tmp_pop_dict[self.sample_pop_dict[sample]]["A"] += self.geno_dict[
                        gt
                    ]
                    total_alternate_allele += self.geno_dict[gt]
                    total_alleles += 2
                    self.sample_local_window_dict[sample][gt] += 1
                    self.sample_local_window_dict[sample]["total_snps"] += 1
                    self.sample_local_window_dict[sample]["average_depth"] += int(dp)
                    if rec.pos > self.previous_window:
                        self.sample_total_dict[sample]["total_snps"] += 1
                        self.sample_total_dict[sample]["average_depth"] += int(dp)
                        self.sample_total_dict[sample][gt] += 1
                    if gt != (0, 0):
                        tmp_pop_dict[self.sample_pop_dict[sample]][type_snps] += 1
                        self.sample_local_window_dict[sample][type_snps] += 1
                        if rec.pos > self.previous_window:
                            self.sample_total_dict[sample][type_snps] += 1
                        if gt == (0, 1):
                            tmp_pop_dict[self.sample_pop_dict[sample]][
                                "average_obs_het"
                            ] += 1
                            self.sample_local_window_dict[sample][
                                "average_obs_het"
                            ] += 1
                            if rec.pos > self.previous_window:
                                self.sample_total_dict[sample]["average_obs_het"] += 1
                    tmp_pop_dict[self.sample_pop_dict[sample]][gt] += 1
                else:
                    self.sample_local_window_dict[sample]["missing_geno"] += 1
                    if rec.pos > self.previous_window:
                        self.sample_total_dict[sample]["missing_geno"] += 1
                    tmp_pop_dict[self.sample_pop_dict[sample]]["missing_geno"] += 1
            if total_alternate_allele / total_alleles > 0.5:
                self.minor_allele = "R"
            self.tmp_pop_dict = tmp_pop_dict.copy()
            self.type_snps = type_snps
            self.pos = rec.pos
            self.calc_pop_stats()

    def write_vcf_stats(self):
        self.pop_list, self.sample_pop_dict = populate_sample_dict(self.sample_map)
        vcf_to_chrom_cords = VcfToChromCords(
            self.vcf_file_name,
            self.bed_in,
            self.bed_ex,
            self.region,
            self.window_size,
            self.step_size,
        )
        chrom_window_dict = vcf_to_chrom_cords.populate_chrom_window_dict()
        self.sample_total_dict, self.pop_total_dict = prepare_sample_pop_dict(
            self.sample_pop_dict, self.params_list, self.pop_list
        )
        self.write_output_headers()
        for chrom in chrom_window_dict:
            chrom_cord_intervals = chrom_window_dict[chrom]
            self.chrom_read = chrom
            self.chrom_present = False
            for cord_interval in chrom_cord_intervals:
                self.cord_window = cord_interval
                self.previous_window = -1
                (
                    self.sample_local_window_dict,
                    self.pop_local_window_dict,
                ) = prepare_sample_pop_dict(
                    self.sample_pop_dict, self.params_list, self.pop_list
                )
                self.read_vcf()
                if self.chrom_present:
                    self.previous_window = cord_interval[1]
                    chrom_interval = (
                        chrom
                        + "\t"
                        + str(cord_interval[0])
                        + "\t"
                        + str(cord_interval[1])
                    )
                    local_pop_str = write_pop_dict(self.pop_local_window_dict)
                    local_sample_str = write_sample_dict(self.sample_local_window_dict)
                    self.dest1.write(chrom_interval.encode())
                    self.dest2.write(chrom_interval.encode())
                    self.dest1.write(local_sample_str.encode())
                    self.dest2.write(local_pop_str.encode())
                    self.dest1.write("\n".encode())
                    self.dest2.write("\n".encode())
        total_pop_str = write_pop_dict(self.pop_total_dict)
        total_sample_str = write_sample_dict(self.sample_total_dict)
        self.dest3.write(local_sample_str.encode())
        self.dest4.write(local_pop_str.encode())
        self.dest3.write("\n".encode())
        self.dest4.write("\n".encode())
        self.dest1.close()
        self.dest2.close()
        self.dest3.close()
        self.dest4.close()
