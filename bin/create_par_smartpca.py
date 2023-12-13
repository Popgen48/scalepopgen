import sys

##implement the help options


def create_par(ped_prefix, num_chrom, num_t, param_file):
    param_list = [
        "indivname:",
        "snpname:",
        "genotypename:",
        "numchrom:",
        "evecoutname:",
        "evaloutname:",
        "numthreads:",
    ]
    with open(ped_prefix + ".smartpca.par", "w") as dest:
        dest.write("indivname: " + ped_prefix + ".ind" + "\n")
        dest.write("snpname: " + ped_prefix + ".snp" + "\n")
        dest.write("genotypename: " + ped_prefix + ".eigenstratgeno" + "\n")
        dest.write("numchrom: " + num_chrom + "\n")
        dest.write("evecoutname: " + ped_prefix + ".evec" + "\n")
        dest.write("evaloutname: " + ped_prefix + ".eval" + "\n")
        dest.write("numthreads: " + num_t + "\n")
        if param_file != "none":
            with open(param_file) as source:
                for line in source:
                    line_l = line.rstrip().split()
                    if not line_l[0] in param_list:
                        dest.write(line)


if __name__ == "__main__":
    create_par(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
