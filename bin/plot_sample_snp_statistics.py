import sys
import yaml
import math
from yaml.loader import SafeLoader
from bokeh.palettes import HighContrast3
from bokeh.plotting import figure, save, output_file
import bokeh.layouts

stats_file = sys.argv[1]
yaml_file = sys.argv[2]
fam_file  = sys.argv[3]
is_vcf = sys.argv[4]
outprefix = sys.argv[5]

is_vcf = True if is_vcf == "vcf" else False

var_category = ["hom_ref", "hom_alt", "het_snp"]
sample_list = []
hom_ref_list = []
hom_alt_list = []
het_snp_list = []
pop_sample_dict = {}
sample_snp_dict = {}
output_file(outprefix + ".html")
tmp_list = []

with open(yaml_file) as p:
    params = yaml.load(p, Loader=SafeLoader)
    figure_width = int(params["width"])
    figure_height = int(params["height"])
    bar_width = float(params["bar_width"])
    font_size = params["x_axis_font_size"]
    sample_label_orientation = int(params["sample_label_orientation"])

with open(fam_file) as source:
    for line in source:
        line = line.rstrip().split()
        pop_id = line[1] if is_vcf else line[0]
        sample_id = line[0] if is_vcf else line[1]
        if pop_id not in pop_sample_dict:
            pop_sample_dict[pop_id] = []
        pop_sample_dict[pop_id].append(sample_id)


header = 0
with open(stats_file) as source:
    for line in source:
        line = line.rstrip().split()
        if header == 0:
            header += 1
        else:
            if line[0] not in sample_snp_dict:
                sample_snp_dict[line[0]] = []
            sample_snp_dict[line[0]].append(int(line[1]))
            sample_snp_dict[line[0]].append(int(line[2]))
            sample_snp_dict[line[0]].append(int(line[3]))

for pop in pop_sample_dict:
    sample_list = []
    hom_ref_list = []
    hom_alt_list = []
    het_snp_list = []
    for sample in pop_sample_dict[pop]:
        sample_list.append(sample)
        hom_ref_list.append(sample_snp_dict[sample][0])
        hom_alt_list.append(sample_snp_dict[sample][1])
        het_snp_list.append(sample_snp_dict[sample][2])
    p = figure(
        x_range=sample_list,
        height=figure_height,
        title=f"SNP count statistics per sample for {pop}",
        toolbar_location=None,
        tools="hover",
        tooltips="$name @sample_list: @$name",
    )
    p.output_backend = "svg"

    data = {
        "sample_list": sample_list,
        "hom_ref": hom_ref_list,
        "hom_alt": hom_alt_list,
        "het_snp": het_snp_list,
    }


    p.vbar_stack(
        var_category,
        x="sample_list",
        width=0.9,
        color=HighContrast3,
        source=data,
        # legend_label=var_category,
    )
    p.y_range.start = 0
    p.x_range.range_padding = 0.1
    p.xgrid.grid_line_color = None
    p.axis.minor_tick_line_color = None
    p.xaxis.major_label_text_font_size = font_size
    # p.legend.location = "top_right"
    # p.legend.orientation = "vertical"
    p.xaxis.major_label_orientation = math.radians(sample_label_orientation)
    tmp_list.append(p)

save(bokeh.layouts.column(children=tmp_list,sizing_mode="scale_width"))
