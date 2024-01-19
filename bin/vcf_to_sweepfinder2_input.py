import sys
import argparse
from pysam import VariantFile
from collections import OrderedDict

class Vcf2SweepfinderInput:
    
    def __init__(self, vcf_in, sample_map, anc, pop, create_recomb, user_recomb, create_grid, outprefix):
        self.vcf_in = vcf_in # read input vcf file
        self.sample_map = sample_map # sample map file
        self.anc = anc # file containing information about ancestral allele
        self.pop = pop # population for which sweepfinder2 input must be created
        self.create_recomb = create_recomb # whether or not to create recombination input file
        self.user_recomb = user_recomb # user-supplied recombination map file in sweepfinder2 format
        self.create_grid = create_grid # whether or not to create grid input file
        self.outprefix = outprefix # outprefix to be set
        self.file_pointer_dict = OrderedDict() #store output file
        self.user_recomb_dict = OrderedDict() #store the recombination distance of user supplied recomb file

    def map_to_dict(self):
        map_dict = {}
        with open(self.sample_map) as source:
            for line in source:
                line = line.rstrip().split()
                map_dict[line[0]] = line[1]
        return map_dict

    def anc_to_dict(self):
        derived_allele_dict = {}
        with open(self.anc) as source:
            for line in source:
                line = line.rstrip().split()
                derived_allele_dict[int(line[1])] = int(line[3])
        return derived_allele_dict

    def pop_file_to_list(self):
        pop_list = []
        with open(self.pop) as source:
            for line in source:
                line = line.rstrip().split()
                pop_list.append(line[0])
        return pop_list

    def create_local_count_dict(self,pop_list):
        local_count_dict = {}
        for pop in pop_list:
            local_count_dict[pop] = [0, 0]
        return local_count_dict

    def init_file_pointer_dict(self, pop_list):
        for popId in pop_list:
            self.file_pointer_dict[popId] = [open(self.outprefix + "_" + popId + ".freq", "w")]
            self.file_pointer_dict[popId][0].write(
                "position" + "\t" + "x" + "\t" + "n" + "\t" + "folded" + "\n"
            )
            if self.create_recomb:
                self.file_pointer_dict[popId].append(
                    open(self.outprefix + ".recomb", "w")
                )
                self.file_pointer_dict[popId][1].write("position" + "\t" + "rate" + "\n")
            if self.create_grid:
                self.file_pointer_dict[popId].append(open(popId + ".grid", "w"))

    def init_create_cm_dict(self,pop_list):
        cm_dict=OrderedDict()
        for pop in pop_list:
            cm_dict[pop] = 0.0
        return cm_dict
    
    def create_recomb_dict(self):
        header = 0
        with open(self.user_recomb) as source:
            for line in source:
                line = line.rstrip().split()
                if header != 0:
                    self.user_recomb_dict[int(line[0])] = float(line[1])
                header += 1
        return self.user_recomb_dict

    
    def write_freq_file(self,pop,pos, x, n, fold):
        self.file_pointer_dict[pop][0].write(
            str(pos)
            + "\t"
            + str(x)
            + "\t"
            + str(n)
            + "\t"
            + str(fold)
            + "\n"
        )

    def write_recomb(self,pop,pos,previous_pos, is_user_recomb):
        if previous_pos == 0.0:
            cm_dist = str(0.0)
        elif is_user_recomb:
            recomb_val = list(self.user_recomb_dict.values())
            pos_i = recomb_val.index(pos)
            previous_pos_i = recomb_val.index(previous_pos)
            cm_dist = str(sum(recomb_val[previous_pos_i+1:pos_i+1]))
        else:
            cm_dist = str((pos-previous_pos)/1000000)
        self.file_pointer_dict[pop][1].write(
            str(pos)
            + "\t"
            + cm_dist
            + "\n"
        )


    def vcf_to_swpfinder2(self):
        map_dict = self.map_to_dict() # process sample map file, output dict, key is sample and value is pop
        is_user_recomb = False
        if self.anc != "ref":
            derived_allele_dict = self.anc_to_dict()
        if self.pop == "all":
            pop_list = list(set(map_dict.values()))
        elif ".txt" in self.pop:
            pop_list = self.pop_file_to_list()
        else:
            pop_list = [self.pop]
        if self.user_recomb:
            is_user_recomb = True
            self.create_recomb_dict()
        init_cm = self.init_create_cm_dict(pop_list)
        self.init_file_pointer_dict(pop_list)
        fold_g = "0" if self.anc != "ref" else "1"
        vcf_pntr = VariantFile(self.vcf_in)
        for rec in vcf_pntr.fetch():
            derived_allele = (
                derived_allele_dict.get(int(rec.pos), "NP") if self.anc != "ref" else 1
            )
            fold, derived_allele = (
                (fold_g, derived_allele) if derived_allele != "NP" else ("1", 1)
            )
            local_count_dict = self.create_local_count_dict(pop_list)
            for sample in map_dict:
                gt = rec.samples[sample]["GT"]
                if gt != (None, None):
                    local_count_dict[map_dict[sample]][0] += gt.count(derived_allele)
                    local_count_dict[map_dict[sample]][1] += 2
            for popId in pop_list:
                if (local_count_dict[popId][0] > 0 and fold == "0") or (fold == "1"):
                    self.write_freq_file(popId, rec.pos,local_count_dict[popId][0],local_count_dict[popId][1],fold)
                    if self.create_recomb:
                        self.write_recomb(popId, rec.pos, init_cm[popId], is_user_recomb)
                        init_cm[popId] = rec.pos
                    if self.create_grid:
                        self.file_pointer_dict[popId][2].write(str(rec.pos) + "\n")
        for popId in pop_list:
            for ptr in self.file_pointer_dict[popId]:
                ptr.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="convert vcf to input of sweepfinder2",
        epilog="author: Maulik Upadhyay (Upadhyaya.maulik@gmail.com)",
    )

    parser.add_argument(
        "-V", "--vcf", metavar="File", help="input vcf file", required=True
    )
    parser.add_argument(
        "-M",
        "--map",
        metavar="File",
        help="map file with first column as sample and second column as pop",
        required=True,
    )
    parser.add_argument(
        "-a",
        "--anc",
        default="ref",
        help="if available provide ancestral alleles file",
    )
    parser.add_argument(
        "-p",
        "--pop",
        metavar="Str",
        help="pop for which sweepfinder2 input is to be created",
        default="all",
        required=False,
    )
    parser.add_argument(
        "-r",
        "--recomb",
        default=False,
        help="whether or not to create recomb map file",
        action="store_true",
    )
    parser.add_argument(
        "-R",
        "--user_recomb",
        default=None,
        help="user supplied recombination map file in sweepfinder2 input format",
    )
    parser.add_argument(
        "-g",
        "--grid",
        default=False,
        help="whether or not to create grid file",
        action="store_true",
    )
    parser.add_argument(
        "-o",
        "--outprefix",
        metavar="Str",
        help="prefix for the output files",
        required=True,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    else:
        v = Vcf2SweepfinderInput(
            args.vcf,
            args.map,
            args.anc,
            args.pop,
            args.recomb,
            args.user_recomb,
            args.grid,
            args.outprefix,
        )
        v.vcf_to_swpfinder2()
