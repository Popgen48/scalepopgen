import sys
import pandas as pd
import yaml
from yaml.loader import SafeLoader
import math
from bokeh.plotting import figure
from bokeh.models import (
    HoverTool,
    ColumnDataSource,
    Range1d,
    Span,
    CustomJS,
    TapTool,
)
from bokeh.plotting import figure
from bokeh.plotting import figure, save, output_file
from bokeh.models.tickers import FixedTicker


class PlotSigSelResults:
    def __init__(
        self, sel_result_out, yml_file, tajimasd_cutoff, window_size, y_label, outprefix
    ):
        self.outprefix = outprefix  # prefix of the output file
        self.sel_result_out = sel_result_out
        self.yml_file = yml_file
        self.tajimasd_cutoff = float(tajimasd_cutoff)
        self.window_size = int(window_size)
        self.min_score = 0  # important to set the min cordi of y axis
        self.max_score = 0  # important to set the maxi cordi of y axis
        self.y_label = y_label  # label will determine the hovering points
        self.upper_hover = ["fst_values"]
        self.axis_chrom_dict = (
            {}
        )  # dictionary with greatest coordinates of a respective chromosome as key and chromosome its value --> use to replace major X-axis with chromosome name

    def read_yml_file(self):
        """
        read yml file and set the parameters corresponding to the interactive plot
        """
        with open(self.yml_file, "r") as p:
            params = yaml.load(p, Loader=SafeLoader)
        self.figure_width = params["width"]
        self.figure_height = params["height"]
        self.chrom_label_orientation = params["chrom_label_orientation"]
        self.legend_font_size = params["legend_font_size"]
        self.label_font_size = params["label_font_size"]
        self.fil_alpha = params["fil_alpha"]
        self.ensembl_link = params["ensembl_link"]
        # self.y_label = params["y_label"]
        self.color_list = params["color_list"]

    def add_nonsigni_df(self, pd1):
        """
        plot the data of non-significant windows
        """
        source = ColumnDataSource(pd1)
        s = self.p.circle(
            "cum_cord",
            "p_val",
            color="col",
            fill_alpha=self.fil_alpha,
            source=source,
        )

    def add_signi_df(self, pd2):
        """
        plot the data of signifincat windows
        """
        source_t = ColumnDataSource(pd2)
        t = self.p.circle(
            "cum_cord",
            "p_val",
            color="col",
            fill_alpha=self.fil_alpha,
            source=source_t,
        )
        if self.ensembl_link != "none":
            toolt = """
                <div>
                    <a href=@link{safe}}>@link{safe}</a>
                </div>
                """
            hvr = HoverTool(renderers=[t], tooltips=toolt)
            self.p.add_tools(hvr)

            tap_cb = CustomJS(
                code="""
                              var l = cb_data.source.data['link'][cb_data.source.inspected.indices[0]]
                              window.open(l)
                              """
            )
            tapt = TapTool(renderers=[t], callback=tap_cb, behavior="inspect")
            self.p.add_tools(tapt)
        else:
            hover = HoverTool(
                tooltips=[("chrom", "@chrom"), ("cord", "@cord")], renderers=[t]
            )
            self.p.add_tools(hover)
            self.p.add_tools(
                HoverTool(tooltips=[("chrom", "@chrom"), ("cord", "@cord")])
            )

    def format_plot(self):
        """
        format the plot using the parameters set in yml file
        """
        self.p.xaxis.major_label_text_font_size = self.label_font_size
        self.p.xaxis.ticker = FixedTicker(ticks=list(self.axis_chrom_dict.keys()))
        self.p.xaxis.major_label_overrides = {
            k: v for k, v in self.axis_chrom_dict.items()
        }
        self.p.xaxis.major_tick_out = 15
        self.p.xaxis.major_label_orientation = math.radians(
            self.chrom_label_orientation
        )
        # self.p.y_range = Range1d(
        #    round(self.min_score) + 1
        #    if self.min_score < round(self.min_score)
        #    else round(self.min_score),
        #    round(self.max_score) + 1
        #    if self.max_score < round(self.max_score)
        #    else round(self.max_score),
        # )
        hline = Span(
            location=self.tajimasd_cutoff,
            dimension="width",
            line_color="red",
            line_width=3,
        )
        self.p.renderers.extend([hline])
        self.p.vspan(x=list(self.axis_chrom_dict.keys()), line_color="black")
        self.p.grid.visible = False
        self.p.xaxis.axis_label = "chromosome_id"
        self.p.yaxis.axis_label = self.y_label

    def sel_out_to_list(self):
        df_list = []
        df_list_t = []
        chrom_list = []
        with open(self.sel_result_out) as source:
            for line in source:
                line = line.rstrip().split()
                if line[-1] != "-nan":
                    self.min_score = (
                        self.min_score
                        if float(line[-1]) > self.min_score
                        else float(line[-1])
                    )
                    self.max_score = (
                        self.max_score
                        if float(line[-1]) < self.max_score
                        else float(line[-1])
                    )
                    tmp_list = []
                    if line[0] not in chrom_list:
                        if len(chrom_list) != 0:
                            self.axis_chrom_dict[cum_cord_1] = chrom_list[-1]
                        chrom_list.append(line[0])
                        color = (
                            self.color_list[0]
                            if len(chrom_list) % 2 == 0
                            else self.color_list[1]
                        )
                    cum_cord_1 = (
                        int(list(self.axis_chrom_dict.keys())[-1]) + int(line[1])
                        if len(chrom_list) > 1
                        else int(line[1])
                    )
                    chrom = line[0]
                    cord = line[1]
                    p_val = float(line[-1])
                    tmp_list = [chrom, cord, cum_cord_1, p_val, color]
                    if self.y_label not in self.upper_hover:
                        if (
                            p_val < float(self.tajimasd_cutoff)
                            and self.ensembl_link != "none"
                        ):
                            tmp_list.append(
                                self.ensembl_link
                                + chrom
                                + ":"
                                + cord
                                + "-"
                                + str(int(cord) + self.window_size)
                            )
                        df_list.append(tmp_list[:]) if p_val > float(
                            self.tajimasd_cutoff
                        ) else df_list_t.append(tmp_list[:])
                    else:
                        if (
                            p_val > float(self.tajimasd_cutoff)
                            and self.ensembl_link != "none"
                        ):
                            tmp_list.append(
                                self.ensembl_link
                                + chrom
                                + ":"
                                + cord
                                + "-"
                                + str(int(cord) + self.window_size)
                            )
                        df_list_t.append(tmp_list[:]) if p_val > float(
                            self.tajimasd_cutoff
                        ) else df_list.append(tmp_list[:])
            self.axis_chrom_dict[cum_cord_1] = chrom_list[-1]
        pd1 = pd.DataFrame(
            df_list, columns=["chrom", "cord", "cum_cord", "p_val", "col"]
        )
        pd2 = pd.DataFrame(
            df_list_t,
            columns=["chrom", "cord", "cum_cord", "p_val", "col", "link"]
            if self.ensembl_link != "none"
            else ["chrom", "cord", "cum_cord", "p_val", "col"],
        )
        return pd1, pd2

    def main_func(self):
        self.read_yml_file()
        self.p = figure(width=self.figure_width, height=self.figure_height)
        self.p.output_backend = "svg"
        output_file(self.outprefix + ".html")
        pd1, pd2 = self.sel_out_to_list()
        self.add_nonsigni_df(pd1)
        self.add_signi_df(pd2)
        self.format_plot()
        save(self.p)


if __name__ == "__main__":
    obk = PlotSigSelResults(
        sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
    )
    obk.main_func()
