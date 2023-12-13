import sys


def create_par(ped_prefix, tool, num_chrom, pop_comb):
    if tool == "convertf":
        with open(ped_prefix + ".ped_to_eigenstraat.par", "w") as dest:
            dest.write("genotypename: " + ped_prefix + ".1.ped" + "\n")
            dest.write("snpname: " + ped_prefix + ".map" + "\n")
            dest.write("indivname: " + ped_prefix + ".1.ped" + "\n")
            dest.write("outputformat: EIGENSTRAT" + "\n")
            dest.write("genotypeoutname: " + ped_prefix + ".eigenstratgeno" + "\n")
            dest.write("snpoutname: " + ped_prefix + ".snp" + "\n")
            dest.write("indivoutname: " + ped_prefix + ".ind" + "\n")
            dest.write("familynames: NO" + "\n")
    if tool == "qp3pop":
        with open(ped_prefix + ".qp3Pop.par", "w") as dest:
            dest.write("indivname: " + ped_prefix + ".ind" + "\n")
            dest.write("snpname: " + ped_prefix + ".snp" + "\n")
            dest.write("genotypename: " + ped_prefix + ".eigenstratgeno" + "\n")
            dest.write("numChrom: " + num_chrom + "\n")
            if pop_comb == "NA":
                dest.write("popfilename: " + ped_prefix + ".qp3PopComb.txt" + "\n")
            else:
                dest.write("popfilename: " + pop_comb + "\n")


if __name__ == "__main__":
    create_par(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
