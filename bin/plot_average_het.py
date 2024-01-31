import sys
import numpy as np
import re
import plotly.graph_objects as go
from collections import OrderedDict
from plink_utils import read_bim_file, read_color_map_file

bim = sys.argv[1]
window_size = sys.argv[2]
color_file = sys.argv[3]
hwe_files = sys.argv[4:]

bim_dict = read_bim_file(bim, window_size)
pop_color_dict = read_color_map_file(color_file)
pop_obs_het_dict = OrderedDict()
pop_exp_het_dict = OrderedDict()
pop_obs_het_dict_genomewide = OrderedDict()
pop_exp_het_dict_genomewide = OrderedDict()


def make_figure(dict_i, dict_c, outprefix):
    fig = go.Figure()
    for pop in dict_i:
        y_val = list(dict_i[pop].values())
        fig.add_trace(go.Box(y=y_val, name=pop, marker_color=dict_c[pop]))
    fig.write_html(outprefix, include_plotlyjs="cdn")


def write_report(dict_oh, dict_eh):
    with open("populationwise_heterozygosity_report.txt", "w") as dest:
        for pop in dict_oh:
            dest.write(
                f"{pop}\t{round(np.mean(dict_oh[pop]),3)} ± {round(np.std(dict_oh[pop]),3)}\t{round(np.mean(dict_eh[pop]),3)} ± {round(np.std(dict_eh[pop]),3)}\n"
            )


"""
with open("bim_windows.txt", "w") as dest:
    for rc in bim_dict:
        dest.write(f"{rc} {bim_dict[rc]}\n")
"""
for hwe_f in hwe_files:
    pattern = "(.*)(_id.hwe)"
    match = re.findall(pattern, hwe_f)
    pop = match[0][0]
    pop_exp_het_dict[pop] = {}
    pop_obs_het_dict[pop] = {}
    pop_exp_het_dict_genomewide[pop] = []
    pop_obs_het_dict_genomewide[pop] = []
    hrc = 0
    hwc = 0
    tmp_oh_l = []
    tmp_eh_l = []
    is_header = True
    with open(hwe_f) as source:
        for line in source:
            if is_header:
                is_header = False
            else:
                line = line.rstrip().split()
                hrc += 1
                c_hwc = bim_dict[hrc]
                pop_obs_het_dict_genomewide[pop].append(float(line[6]))
                pop_exp_het_dict_genomewide[pop].append(float(line[7]))
                if c_hwc != hwc:
                    if len(tmp_eh_l) > 0:
                        pop_obs_het_dict[pop][hwc] = round(float(np.mean(tmp_oh_l)), 3)
                        pop_exp_het_dict[pop][hwc] = round(float(np.mean(tmp_eh_l)), 3)
                        del tmp_eh_l[:]
                        del tmp_oh_l[:]
                    hwc = c_hwc
                tmp_eh_l.append(float(line[7]))
                tmp_oh_l.append(float(line[6]))
    pop_obs_het_dict[pop][hwc] = round(float(np.mean(tmp_eh_l)), 3)
    pop_exp_het_dict[pop][hwc] = round(float(np.mean(tmp_eh_l)), 3)
    make_figure(pop_obs_het_dict, pop_color_dict, "obs_het.html")
    make_figure(pop_exp_het_dict, pop_color_dict, "exp_het.html")
    write_report(pop_obs_het_dict_genomewide, pop_exp_het_dict_genomewide)
