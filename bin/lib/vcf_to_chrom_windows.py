import sys

if sys.version_info < (3, 7):
    raise RuntimeError("This package requres Python 3.7+")

import pybedtools
from pysam import VariantFile
import re
import tempfile
import argparse

# this class will return list of coordinates to processed given vcf file, bed files, window size and step size


class VcfToChromCords:
    def __init__(self, vcf_in, bed_in, bed_ex, region_in, window_size, step_size):
        self.vcf_in = VariantFile(vcf_in)  # vcf file to open
        self.bed_in = bed_in  # regions to include
        self.bed_ex = bed_ex  # regions to exclude
        self.region_in = region_in  # region in the format: chrm:start-window
        self.window = int(window_size)  # window size
        self.step = int(step_size)  # step size
        self.chrom_list = []
        self.is_region_window = False
        self.tmp_bed = tempfile.TemporaryFile(mode="r+")  # temporary bed file
        self.chrom_cord_dict = {}  # key --> chrom , val --> list[1, length]

    # if region_in argument contains ".txt" then it should be uniform
    # either ".txt" should contain the list of chromosome alone chr1, chr2 etc
    # or should contain :, e.g. chr1:1000-2000 etc. in all the lines

    def read_region_in(self):
        if ".txt" in self.region_in:
            with open(self.region_in) as source:
                for line in source:
                    line = line.rstrip().split(":")
                    if len(line) == 1:
                        self.chrom_list.append(line[0])
                    else:
                        self.is_region_window = True
                        if line[0] not in self.chrom_cord_dict:
                            self.chrom_cord_dict[line[0]] = []
                        cords = line[1].split("-")
                        self.chrom_cord_dict[line[0]].append(
                            [int(cords[0]), int(cords[1])]
                        )
        elif ":" in self.region_in:
            chrm = self.region_in.split(":")[0]
            start = self.region_in.split(":")[1].split("-")[0]
            end = self.region_in.split(":")[1].split("-")[1]
            self.is_region_window = True
            self.chrom_cord_dict[chrm] = [[int(start), int(end)]]
        else:
            self.chrom_list.append(self.region_in)

    # if bed file of the regions to be included is provided then population self.chrom_cord_dict with bed file regions

    def read_bed_inc(self):
        with open(self.bed_in) as source:
            for line in source:
                line = line.rstrip().split("\t")
                if line[0] not in self.chrom_cord_dict:
                    self.chrom_cord_dict[line[0]] = []
                self.chrom_cord_dict[line[0]].append([int(line[1]), int(line[2])])

    # read header of the vcf and store chrom and its size in chrom_cord_dict
    # structure, {chrm1:[[1,158368000]]}

    def populate_whole_chrom_cord_dict(self):
        for rec in self.vcf_in.header.records:
            if (str(rec)).startswith("##contig"):
                pattern = re.compile(r"ID\=([^,]*),length=([0-9]+)")
                match = re.findall(pattern, str(rec))
                chrom = ""
                if len(self.chrom_list) > 0:
                    if match[0][0] in self.chrom_list:
                        chrom = match[0][0]
                    else:
                        chrom = ""
                else:
                    chrom = match[0][0]
                if chrom != "":
                    self.chrom_cord_dict[chrom] = [[1, int(match[0][1])]]

    # if bed file of the regions to be excluded is provided then use subtract method of pybedtools

    def subtract_bed(self):
        for chrom in self.chrom_cord_dict:
            regions = self.chrom_cord_dict[chrom]
            for region in regions:
                self.tmp_bed.write(
                    chrom + "\t" + str(region[0]) + "\t" + str(region[1]) + "\n"
                )
        tmp_chrom_cord_dict = {}
        self.tmp_bed.seek(0)
        file_a = pybedtools.BedTool(self.tmp_bed)
        file_b = pybedtools.BedTool(self.bed_ex)
        for bed_record in file_a.subtract(file_b):
            record_interval = str(bed_record).rstrip().split()
            if record_interval[0] not in tmp_chrom_cord_dict:
                tmp_chrom_cord_dict[record_interval[0]] = []
            tmp_chrom_cord_dict[record_interval[0]].append(
                [int(record_interval[1]), int(record_interval[2])]
            )
        return tmp_chrom_cord_dict

    # following codes create the dictionary of chromosome windows to process (based on the user-defined criteria)
    # if window size=5 and step size=0, then
    # structure --> {"chrm1":[[1,5],[6,10],[15,20],[21,25],[26,26]]}

    def split_window(self, chrom_dict):
        tmp_chrom_cord_dict = {}
        for chrom in chrom_dict:
            chrom_cord = chrom_dict[chrom]
            tmp_chrom_cord_dict[chrom] = []
            for cord in chrom_cord:
                for i in range(cord[0], cord[1], self.step):
                    if i + self.window < cord[1]:
                        tmp_chrom_cord_dict[chrom].append([i, i + self.window])
                    else:
                        tmp_chrom_cord_dict[chrom].append([i, cord[1]])
        return tmp_chrom_cord_dict

    # following method create the dictionary structure to hold the chromosome ranges to process
    # structure --> {"chrm1":[[1,10],[15,26]],"chrm2":[[1,10],[15,26]]}

    def populate_chrom_window_dict(self):
        if self.region_in != None:
            self.read_region_in()
        if self.bed_in != None:
            self.read_bed_inc()
        elif not self.is_region_window:
            self.populate_whole_chrom_cord_dict()
        else:
            pass
        if self.bed_ex != None:
            final_chrom_cord_dict = self.subtract_bed()
        else:
            final_chrom_cord_dict = self.chrom_cord_dict
        if self.window == 0:
            chrom_cord_list_dict = final_chrom_cord_dict
        else:
            chrom_cord_list_dict = self.split_window(final_chrom_cord_dict)
        return chrom_cord_list_dict


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=" given vcf and bed files this program outputs the genomics windows to process",
        epilog="author: Maulik Upadhyay (Upadhyay.maulik@gmail.com)",
    )
    requiredNamed = parser.add_argument_group("required name arguments")
    requiredNamed.add_argument(
        "-v", "--vcf", metavar="File", help="vcf file", required=True
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
    parser.add_argument(
        "-r",
        "--region",
        metavar="Str",
        help="genomic region to be included",
        default=None,
        required=False,
    )
    parser.add_argument(
        "-w",
        "--window",
        metavar="Int",
        help="window size (default:50000)",
        default=50000,
        required=False,
    )
    parser.add_argument(
        "-s",
        "--step",
        metavar="Int",
        help="step size (default:50000)",
        default=50000,
        required=False,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
    else:
        vcf_to_chrom_cords = VcfToChromCords(
            args.vcf, args.bed_incl, args.bed_excl, args.region, args.window, args.step
        )
        chrom_cord_list_dict = vcf_to_chrom_cords.populate_chrom_window_dict()
        with open("cords_to_process.bed", "w") as dest:
            for chrom in chrom_cord_list_dict:
                regions = chrom_cord_list_dict[chrom]
                for region in regions:
                    dest.write(
                        chrom + "\t" + str(region[0]) + "\t" + str(region[1]) + "\n"
                    )
