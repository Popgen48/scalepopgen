import sys
import argparse

def skip_pop_list(skip_p):
    skip_pop_l = []
    with open(skip_p) as source:
        for line in source:
            line = line.rstrip().split()
            skip_pop_l.append(line[0])
    return skip_pop_l

def read_map(map_f):
    pop_sample_dict = {}
    with open(map_f) as source:
        for line in source:
            line = line.rstrip().split()
            if line[1] not in pop_sample_dict:
                pop_sample_dict[line[1]] = []
            pop_sample_dict[line[1]].append(line[0])
    return pop_sample_dict

def split_sample_map(map_f, min_s, skip_p, skip_o, outgroup, tool, outprefix):
    skip_pop_l = []
    if skip_p:
        skip_pop_l = skip_pop_list(skip_p)
    if skip_o:
        skip_pop_l.append(outgroup)
    pop_sample_dict = read_map(map_f)
    with open(outprefix+"_included_samples.csv","w") as dest_g:
        for pop in pop_sample_dict:
            if len(pop_sample_dict[pop])>=int(min_s) and pop not in skip_pop_l:
                with open(pop+".txt","w") as dest:
                    dest_g.write("\n".join(pop_sample_dict[pop])+"\n")
                    if tool != "sweepfinder2":
                        dest.write("\n".join(pop_sample_dict[pop])+"\n")
                    else:
                        for sample in pop_sample_dict[pop]:
                            dest.write(f"{sample} {pop}\n")

        

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="python script to split sample map file for selection",
    )
    parser.add_argument(
        "-m",
        "--sample_map",
        metavar="Str",
        help="sample map file with first column as sample id and second column as pop id",
        required=True,
    )
    parser.add_argument(
        "-n",
        "--min_sample_size",
        metavar="Str",
        help="chromosom id for which treemix input file is to be prepared",
        default=0,
        required=False,
    )
    parser.add_argument(
        "-p",
        "--skip_pop",
        metavar="Str",
        help="file containing population id to be excluded from the analysis",
        default=None,
        required=False,
    )
    parser.add_argument(
        "-s",
        "--skip_outgroup",
        metavar="Bool",
        help="whether or not to skip the outgroup samples from the selection analysis",
        default=True,
        required=False,
    )
    parser.add_argument(
        "-r",
        "--outgroup",
        metavar="Str",
        help="population id of the outgroup in map file",
        default=None,
        required=False,
    )
    parser.add_argument(
        "-t",
        "--tool",
        metavar="Str",
        help="tool for which the map file is splitted",
        default="vcftools",
        required=False,
    )
    parser.add_argument(
        "-o",
        "--outprefix",
        metavar="Str",
        help="prefix of the output file",
        required=True,
    )
    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
    else:
        split_sample_map(args.sample_map, args.min_sample_size, args.skip_pop, args.skip_outgroup, args.outgroup, args.tool, args.outprefix)
