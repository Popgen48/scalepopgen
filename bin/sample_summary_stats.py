import sys

if sys.version_info < (3, 7):
    raise RuntimeError("This package requres Python 3.7+")
import gzip
import argparse
from pysam import VariantFile
from lib.file_processes import (
    prepare_sample_pop_dict,
    write_sample_dict,
    write_pop_dict,
    prepare_sample_param_dict,
)
from lib.vcf_to_chrom_windows import VcfToChromCords


# the following class calculate sample-wise summary statistics using window size and step size


class SampleSummaryStats:
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
        self.sample_total_stat = (
            {}
        )  # dictionary storing overall statistics (as opposed to local window based statistics)
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
            "ts",
            "tv",
            "monomorphic",
        ]  # these are the summary statistics to be written in the output files
        self.geno_dict = {(0, 0): 0, (0, 1): 1, (1, 1): 2}
        self.transitions = [["A", "G"], ["G", "A"], ["C", "T"], ["T", "C"]]

    # following method will prepare sample_pop_dict, mode --> 0
    def process_sample_map(self):
        self.sample_pop_dict = prepare_sample_pop_dict(self.sample_map, 0)
        self.sample_list = list(self.sample_pop_dict.keys())

    # following method will prepare list of windows of coordinates to be processed, more details in ---> VcfToChromCords
    def prepare_chrom_cords(self):
        vcf_to_chrom_cords = VcfToChromCords(
            self.vcf_file_name,
            self.bed_in,
            self.bed_ex,
            self.region,
            self.window_size,
            self.step_size,
        )
        self.chrom_cord_dict = vcf_to_chrom_cords.populate_chrom_window_dict()

    # following method create the output dictionary for sample or populations, mode 0 --> input is sample list, mode 1 --> input is pop list
    # self.params_list=[(0, 0),(0, 1),(1, 1),"missing_geno","total_snps","average_depth","average_obs_het","ts","tv"]
    # structure --> {"sample1":{(0,0):0,(0,1):0,(1,1):0,"missing_geno":0,"total_snps":0,"average_depth":0,"average_obs_het":0,"ts":0,"tv":0}}

    def prepare_sample_param_dict(self):
        sample_param_dict = prepare_sample_param_dict(
            self.sample_list, self.params_list, 0
        )
        return sample_param_dict

    # following method open the gzipped output files to write
    # destL --> sample-wise window-based summary statistics
    # destG --> sample-wise overall summary statistics

    def write_output_headers(self):
        self.destL = gzip.open(self.out_prefix + "_sample_local_summary.gz", "wb")
        destLHeader = (
            "chom:start-end"
            + "\t"
            + "\t".join(list(self.sample_pop_dict.keys()))
            + "\n"
        )  # make sure that python version is above 3.8 as the order of key matters in here
        self.destL.write(destLHeader.encode())
        self.destG = gzip.open(self.out_prefix + "_sample_total_summary.gz", "wb")
        destGHeader = "\t".join(list(self.sample_pop_dict.keys())) + "\n"
        self.destG.write(destGHeader.encode())

    # read vcf file for each window and calculate individual sample statistics
    # note the use of self.previous_window variable --> used to make sure that overlapped position do not get count twice in self.sample_total_dict

    def read_vcf(self):
        for rec in self.vcf_in.fetch(
            self.chrom_read, self.cord_window[0], self.cord_window[1]
        ):
            self.is_chrom_present = True
            if rec.alts != None:  # the site is genotyped but does not contain SNP
                snps = [rec.ref[0], rec.alts[0]]
                type_snps = ["ts" if snps in self.transitions else "tv"][0]
            else:
                type_snps = "monomorphic"  ## this site does not contain any SNPs --> equal in all samples
            for sample in self.sample_local_window_dict:
                gt = rec.samples[sample]["GT"]
                dp = (
                    rec.samples[sample]["DP"]
                    if rec.samples[sample]["DP"] != None
                    else 0
                )  # if sample is jointly genotyped, it might happen that a sample has no read covered at a particular position, set DP=0 for such cases
                # further, if DP is set to 0, the genotype is missing and hence, will not pass the if condition
                if gt in self.params_list:
                    self.sample_local_window_dict[sample][gt] += 1
                    self.sample_local_window_dict[sample]["total_snps"] += 1
                    self.sample_local_window_dict[sample]["average_depth"] += int(dp)
                    self.sample_local_window_dict[sample][type_snps] += 1
                    if rec.pos > self.previous_window:
                        self.sample_total_dict[sample]["total_snps"] += 1
                        self.sample_total_dict[sample]["average_depth"] += int(dp)
                        self.sample_total_dict[sample][gt] += 1
                        self.sample_total_dict[sample][type_snps] += 1
                else:
                    self.sample_local_window_dict[sample]["missing_geno"] += 1
                    if rec.pos > self.previous_window:
                        self.sample_total_dict[sample]["missing_geno"] += 1

    def write_vcf_stats(self):
        self.process_sample_map()  # ---> first process sample map file
        self.prepare_chrom_cords()  # ---> prepare chromosome coordinates to be processed
        self.sample_total_dict = (
            self.prepare_sample_param_dict()
        )  # ---> prepare a dictionary to write total output
        self.write_output_headers()  # ---> write header of the output files
        for chrom in self.chrom_cord_dict:
            chrom_cord_intervals = self.chrom_cord_dict[chrom]
            self.chrom_read = chrom
            self.is_chrom_present = False  # sometime it happens that chrom is only present in header but no record in vcf file, check for this
            for cord_interval in chrom_cord_intervals:
                self.cord_window = cord_interval
                self.previous_window = (
                    -1
                )  # initialized to not count the overlapped position in global statistics as opposed to local
                self.sample_local_window_dict = (
                    self.prepare_sample_param_dict()
                )  # for each window prepare the dictionary with output statistics
                self.read_vcf()  # read vcf file
                if self.is_chrom_present:
                    self.previous_window = cord_interval[
                        1
                    ]  # update to the boundary of the processed window
                    chrom_interval = (
                        chrom
                        + "\t"
                        + str(cord_interval[0])
                        + "\t"
                        + str(cord_interval[1])
                    )
                    local_sample_str = write_sample_dict(self.sample_local_window_dict)
                    self.destL.write(chrom_interval.encode())
                    self.destL.write(local_sample_str.encode())
                    self.destL.write("\n".encode())
        total_sample_str = write_sample_dict(self.sample_total_dict)
        self.destG.write(total_sample_str.encode())
        self.destG.write("\n".encode())
        self.destL.close()
        self.destG.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=" given vcf file and sample map file this tool outputs the sample summary statistics",
        epilog="author: Maulik Upadhyay (Upadhyay.maulik@gmail.com)",
    )
    requiredNamed = parser.add_argument_group("required name arguments")
    requiredNamed.add_argument(
        "-v", "--vcf", metavar="File", help="vcf file", required=True
    )
    requiredNamed.add_argument(
        "-m", "--map", metavar="File", help="sample map file", required=True
    )
    requiredNamed.add_argument(
        "-o", "--out", metavar="Str", help="output prefix", required=True
    )
    parser.add_argument(
        "-w",
        "--window",
        metavar="Int",
        help="window size",
        default=50000,
        required=False,
    )
    parser.add_argument(
        "-s", "--step", metavar="Int", help="step size", default=50000, required=False
    )
    parser.add_argument(
        "-r",
        "--region",
        metavar="Str",
        help="genomic region to be included",
        default=None,
        required=False,
    )
    parser.add_argument(
        "-b",
        "--bed_incl",
        metavar="File",
        help="bed file of the regions to be included",
        default=None,
        required=False,
    )
    parser.add_argument(
        "-B",
        "--bed_excl",
        metavar="File",
        help="bed file of the regions to be excluded",
        default=None,
        required=False,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
    else:
        sample_summary_stats = SampleSummaryStats(
            args.vcf,
            args.map,
            args.window,
            args.step,
            args.out,
            args.region,
            args.bed_incl,
            args.bed_excl,
        )
        sample_summary_stats.write_vcf_stats()
