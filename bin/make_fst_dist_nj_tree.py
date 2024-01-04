import sys
from Bio.Phylo.TreeConstruction import DistanceMatrix
from Bio.Phylo.TreeConstruction import DistanceTreeConstructor
from Bio import Phylo
import toytree
import toyplot
import toyplot.svg
import yaml
from yaml.loader import SafeLoader
import argparse


def read_dist_file(in_file):
    pairwise_fst_dict = {}
    pop_list = []
    header = 0
    with open(in_file) as source:
        for line in source:
            if header == 0:
                header += 1
            else:
                line = line.rstrip().split()
                pop1 = line[0]
                pop2 = line[1]
                fst = float(line[2])
                if pop1 not in pop_list:
                    pop_list.append(pop1)
                if pop2 not in pop_list:
                    pop_list.append(pop2)
                pairwise_fst_dict[pop1 + "_" + pop2] = fst
    pop_list.sort()
    return pairwise_fst_dict, pop_list


def plot_interactive_tree(newickfile, pop_color_file, plot_yml, outgroup):
    newick = ""
    pop_color_dict = {}
    color_list = []
    with open(plot_yml, "r") as p:
        params = yaml.load(p, Loader=SafeLoader)
    hgt = params["height"]
    wth = params["width"]
    layo = params["layout"]
    tla = params["tip_label_align"]
    tlf = params["tip_label_font_size"]
    ns = params["node_sizes"]
    nh = params["node_hover"]
    tas = params["toyplot-anchor-shift"]
    with open(pop_color_file) as source:
        for line in source:
            line = line.rstrip().split()
            pop_color_dict[line[0]] = line[2]
    with open(newickfile) as source:
        for line in source:
            line = line.rstrip()
            newick = line
    tre1 = toytree.tree(newick, tree_format=1)
    if outgroup != "none":
        tre1 = tre1.root(names=[outgroup])
    pop_list = tre1.get_tip_labels()
    for pop in pop_list:
        if pop not in pop_color_dict:
            pop = pop[
                1:
            ]  ## if within cluster id starts with the number then plink2 by default add "C" to each cateogry
        color_list.append(pop_color_dict[pop])
    canvas, axes, mark = tre1.draw(
        height=hgt,
        width=wth,
        layout=layo,
        node_hover=nh,
        node_sizes=ns,
        tip_labels_align=tla,
        tip_labels_colors=color_list,
        tip_labels_style={
            "font-size": tlf,
            "-toyplot-anchor-shift": tas,
        },
    )
    toyplot.html.render(canvas, newickfile + ".html")
    toyplot.svg.render(canvas, newickfile + ".svg")


def make_fst_tree(in_file, tree, outgroup, f_pop_color, plot_yml, out_prefix):
    pairwise_fst_dict, pop_list = read_dist_file(in_file)
    distance_list = []
    dest = open(out_prefix + ".fst.dist", "w")
    dest.write(" " + str(len(pop_list)) + "\n")
    for i, v in enumerate(pop_list):
        tmp_list = []
        col1 = v + " " * (10 - len(v)) if len(v) < 10 else v[:10] + " "
        dest.write(col1)
        for it, vt in enumerate(pop_list[:i]):
            fst = (
                pairwise_fst_dict[v + "_" + vt]
                if v + "_" + vt in pairwise_fst_dict
                else pairwise_fst_dict[vt + "_" + v]
            )
            tmp_list.append(round(fst, 4))
        tmp_list.append(0)
        tmp_list_w = ["{:.4f}".format(x) for x in tmp_list]
        dest.write(" ".join(tmp_list_w) + "\n")
        distance_list.append(tmp_list[:])
    dm = DistanceMatrix(pop_list, distance_list)
    constructor = DistanceTreeConstructor()
    if tree == "UPGMA":
        tree = constructor.upgma(dm)
    else:
        tree = constructor.nj(dm)
    if outgroup != "none":
        tree.root_with_outgroup({"name": outgroup})
    Phylo.write(tree, out_prefix + "_fst.tree", "newick")
    plot_interactive_tree(out_prefix + "_fst.tree", f_pop_color, plot_yml, outgroup)
    dest.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="A small python script to generate NJ-based tree based on pairwise-Fst distances generated \
    using vcftools",
        epilog="author: Maulik Upadhyay (Upadhyay.maulik@gmail.com)",
    )
    parser.add_argument(
        "-i",
        "--in_file",
        metavar="String",
        help="plink generated global pairwise fst values between each pair of population",
        required=True,
    )
    parser.add_argument(
        "-t",
        "--tree",
        metavar="String",
        help="type of algorithms to be used in building tree: NJ or UPGMA (defualt = NJ) \
    ",
        default="NJ",
        required=False,
    )
    parser.add_argument(
        "-r",
        "--outgroup",
        metavar="String",
        help="population name to be used as outgroup",
        default="none",
        required=False,
    )
    parser.add_argument(
        "-c",
        "--pop_color",
        metavar="String",
        default="none",
        help="path to the text file containing pop id as first column and hex id of a color in the second column",
        required=False,
    )
    parser.add_argument(
        "-y",
        "--plot_nj_yml",
        metavar="String",
        help="path to the yml file containing parameters to plot interactive nj tree. Refer to ./paramteres/plot_nj_tree/plot_nj.yml",
        required=True,
    )
    parser.add_argument(
        "-o", "--out_prefix", metavar="File", help="output prefix", required=True
    )

    args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    elif args.tree not in ["NJ", "UPGMA"]:
        print("ERROR: the tree option should either be NJ or UPGMA")
    else:
        make_fst_tree(
            args.in_file,
            args.tree,
            args.outgroup,
            args.pop_color,
            args.plot_nj_yml,
            args.out_prefix,
        )
