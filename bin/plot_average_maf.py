import sys
import numpy as np
import plotly.graph_objects as go
from collections import OrderedDict
from plink_utils import read_bim_file, read_color_map_file

bim = sys.argv[1]
window_size = sys.argv[2]
color_file = sys.argv[3]
maf_file = sys.argv[4]

bim_dict = read_bim_file(bim, window_size)
pop_color_dict = read_color_map_file(color_file)


def make_figure(dict_i, dict_c, outprefix):
    fig = go.Figure()
    for pop in dict_i:
        y_val = list(dict_i[pop].values())
        fig.add_trace(go.Box(y=y_val, name=pop, marker_color=dict_c[pop]))
    fig.write_html(outprefix, include_plotlyjs="cdn")


def write_report(dict_maf):
    with open("populationwise_maf_report.txt", "w") as dest:
        for pop in dict_maf:
            dest.write(
                f"{pop}\t{round(np.mean(dict_maf[pop]),3)} ± {round(np.std(dict_maf[pop]),3)}\n"
            )


"""
with open("bim_windows.txt", "w") as dest:
    for rc in bim_dict:
        dest.write(f"{rc} {bim_dict[rc]}\n")
"""

pop_maf_dict = {}
hrc = 0
hwc = 0
is_header = True
t_pop_maf_dict = {}
tmp_pop_list = []
pop_maf_dict_genomewide = {}

# read plink generated maf file with the suffix,"frq.strat"
with open(maf_file) as source:
    for line in source:
        if is_header:
            is_header = False #first line is always header
            hrc += 1
        else:
            line = line.rstrip().split()
            if line[2] in tmp_pop_list:
                hrc += 1
                del tmp_pop_list[:]
            c_hwc = bim_dict[hrc] # window count of current record based on bim_dict
            if c_hwc != hwc:
                if len(t_pop_maf_dict) > 0:
                    for pop in t_pop_maf_dict:
                        pop_maf_dict[pop][hwc] = round(
                            float(np.mean(t_pop_maf_dict[pop])), 3
                        )
                t_pop_maf_dict.clear()
                hwc = c_hwc # assign window count to the current record based on bim_dict 
            if line[2] not in t_pop_maf_dict:
                t_pop_maf_dict[line[2]] = []
            if line[2] not in pop_maf_dict:
                pop_maf_dict[line[2]] = {}
                pop_maf_dict_genomewide[line[2]] = []
            t_pop_maf_dict[line[2]].append(float(line[5]))
            tmp_pop_list.append(line[2])
            pop_maf_dict_genomewide[line[2]].append(float(line[5]))

for pop in t_pop_maf_dict:
    pop_maf_dict[pop][hwc] = round(float(np.mean(t_pop_maf_dict[pop])), 3)

write_report(pop_maf_dict_genomewide)
make_figure(pop_maf_dict, pop_color_dict, "maf_summary.html")
