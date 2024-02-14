import sys
import argparse
from pysam import VariantFile


def map_to_dict(sample_map, outgroup_id):
    """
    inputs are --> sample map file and outgroup id
    objective --> prepare two dictionaries, sample_dict = {"sample1":"focal","sample2":"outgroup"}; this dict contain info of all samples incl. outgroup
              --> another dictionary, pop_dict = {"focal":["sample1","sample2","sample3"]}; this dict does contains outgroup samples
    """
    sample_dict = {}
    pop_dict = {"focal": []}
    outgroup_list = [outgroup_id]
    pop_dict[outgroup_id]=[]
    with open(sample_map) as source:
        for line in source:
            line = line.rstrip().split()
            if line[1] in outgroup_list:
                sample_dict[line[0]] = line[1]
                pop_dict[line[1]].append(line[0])
            else:
                sample_dict[line[0]] = "focal"
                pop_dict["focal"].append(line[0])
    n_pop = len(outgroup_list)
    return sample_dict, pop_dict, n_pop


def find_consensus_base_outgroup(base_dict):
    '''
    est-sfs assumes outgroup as haploid, therefore, the total count for each outgroup allele should be "1"
    input --> {'A': 0, 'C': 1, 'G': 0, 'T': 5}
    output -> [0, 0, 0, 1]
    '''
    max_idx = list(base_dict.values()).index(max(base_dict.values()))
    cons_list = [1 if i == max_idx else 0 for i in range(4)]
    return cons_list


def write_param(chrom, n_pop, model, n_random):
    dest_c = open(chrom + "_config.txt", "w")
    dest_s = open(chrom + "_seed.txt", "w")
    dest_c.write(
        "n_outgroup "
        + str(n_pop)
        + "\n"
        + "model "
        + str(model)
        + "\n"
        + "nrandom "
        + str(n_random)
        + "\n"
    )
    dest_s.write("345678" + "\n")
    dest_c.close()
    dest_s.close()


def vcf_to_est_sfs(chrom, vcf_in, sample_map, outgroup_id, model, n_random):
    sample_dict, pop_dict, n_pop = map_to_dict(sample_map, outgroup_id)
    vcf_pntr = VariantFile(vcf_in)
    dest_m = open(chrom + "_non_missing_sites.map", "w")
    with open(chrom + "_data.txt", "w") as dest_d:
        for rec in vcf_pntr.fetch():
            missing = 0
            ref_allele_count = 0
            alt_allele_count = 0
            snps = [
                rec.ref[0].upper(),
                rec.alts[0].upper(),
            ]  # ref or alt alleles can be in lower case
            pop_base_dict = {}
            for pop in pop_dict:
                pop_base_dict[pop] = {"A": 0, "C": 0, "G": 0, "T": 0}
            for sample in sample_dict:
                gt = rec.samples[sample]["GT"]
                if sample_dict[sample] == "focal":
                    focal_sp = True
                else:
                    focal_sp = False
                if gt[0] == None:
                    missing = 1
                    break
                elif gt == (0, 0):
                    pop_base_dict[sample_dict[sample]][snps[0]] += 2
                    ref_allele_count = (
                        ref_allele_count + 2 if focal_sp else ref_allele_count
                    )
                elif gt == (1, 1):
                    pop_base_dict[sample_dict[sample]][snps[1]] += 2
                    alt_allele_count = (
                        alt_allele_count + 2 if focal_sp else alt_allele_count
                    )
                elif gt == (0, 1) or gt == (1, 0):
                    pop_base_dict[sample_dict[sample]][snps[0]] += 1
                    pop_base_dict[sample_dict[sample]][snps[1]] += 1
                    ref_allele_count = (
                        ref_allele_count + 1 if focal_sp else ref_allele_count
                    )
                    alt_allele_count = (
                        alt_allele_count + 1 if focal_sp else alt_allele_count
                    )
                else:
                    print("invalid genotypes at " + str(rec.pos) + "\n")
                    sys.exit(1)
            f_line = ""
            o_line = ""
            for k in pop_base_dict:
                if missing == 0:
                    if k == "focal":
                        f_line += ",".join(map(str, pop_base_dict[k].values())) + " "
                    else:
                        base_count_list = find_consensus_base_outgroup(pop_base_dict[k])
                        o_line += ",".join(map(str, base_count_list)) + " "
            w_line = f_line.rstrip() + " " + o_line.rstrip()
            if missing == 0:
                dest_d.write(w_line + "\n")
                dest_m.write(
                    str(rec.chrom)
                    + "\t"
                    + str(rec.pos)
                    + "\t"
                    + str(1 if alt_allele_count > ref_allele_count else 0)
                    + "\n"
                )
    dest_m.close()
    write_param(chrom, n_pop, model, n_random)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="convert vcf to input of sweepfinder2",
        epilog="author: Maulik Upadhyay (Upadhyaya.maulik@gmail.com)",
    )
    parser.add_argument(
        "-c", "--chrom", metavar="Str", help="chromosome string", required=True
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
        "-o",
        "--outgroup",
        metavar="Str",
        help="outgroup id",
        required=True,
    )
    parser.add_argument(
        "-m",
        "--Model",
        metavar="Int",
        help="0: Jukes-Cantor model, 1: Kimura 2-parametr model, 2: Rate-6 model",
        default=0,
        required=False,
    )
    parser.add_argument(
        "-n",
        "--n_random",
        metavar="Int",
        help="nrandom as mentioned in the manual of the program est-sfs",
        default=5,
        required=False,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    else:
        vcf_to_est_sfs(
            args.chrom, args.vcf, args.map, args.outgroup, args.Model, args.n_random
        )
