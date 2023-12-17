import sys
import random
import yaml
from yaml.loader import SafeLoader
from bokeh.plotting import figure, save, output_file
from bokeh.models import HoverTool, ColumnDataSource, Legend


class PlotInteractivePca:
    def __init__(self, evec_file, eval_file, pop_color_map, yaml_file, outprefix):
        self.evec_file = evec_file
        self.eval_file = eval_file
        self.pop_color_map = pop_color_map
        self.outprefix = outprefix
        self.yaml_file = yaml_file
        self.evec_dict = {}
        self.pop_color_dict = {}
        self.legend_loc_list = []
        self.shape_method_dict = {
            "circle_default": self.plot_circle_default,
            "asterisk_default": self.plot_aserisk_default,
            "circle_cross": self.plot_circle_cross,
            "circle_dot": self.plot_circle_dot,
            "circle_x": self.plot_circle_xp,
            "circle_y": self.plot_circle_y,
            "cross_default": self.plot_cross_default,
            "diamond_default": self.plot_diamond_default,
            "diamond_dot": self.plot_diamond_dot,
            "diamond_cross": self.plot_diamond_cross,
            "dot_default": self.plot_dot_default,
            "hex_default": self.plot_hex_default,
            "hex_dot": self.plot_hex_dot,
            "invertedtriangle_default": self.plot_invertedtriangle_default,
            "plus_default": self.plot_plus_default,
            "square_default": self.plot_square_default,
            "square_cross": self.plot_square_cross,
            "square_dot": self.plot_square_dot,
            "square_pin": self.plot_square_pin,
            "square_x": self.plot_square_x,
            "star_default": self.plot_star_default,
            "star_dot": self.plot_star_dot,
            "triangle_default": self.plot_triangle_default,
            "triangle_dot": self.plot_triangle_dot,
            "triangle_pin": self.plot_triangle_pin,
        }

    def plot_circle_default(self, source):
        fc = self.p.circle(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_aserisk_default(self, source):
        fc = self.p.asterisk(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_circle_cross(self, source):
        fc = self.p.circle_cross(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_circle_dot(self, source):
        fc = self.p.circle_dot(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_circle_xp(self, source):
        fc = self.p.circle_x(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_circle_y(self, source):
        fc = self.p.circle_y(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_cross_default(self, source):
        fc = self.p.cross(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_diamond_default(self, source):
        fc = self.p.diamond(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_diamond_cross(self, source):
        fc = self.p.diamond_cross(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_diamond_dot(self, source):
        fc = self.p.diamond_dot(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_dot_default(self, source):
        fc = self.p.dot(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_hex_default(self, source):
        fc = self.p.hex(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_hex_dot(self, source):
        fc = self.p.hex_dot(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_invertedtriangle_default(self, source):
        fc = self.p.inverted_triangle(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_plus_default(self, source):
        fc = self.p.plus(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_square_default(self, source):
        fc = self.p.square(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_square_cross(self, source):
        fc = self.p.square_cross(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_square_dot(self, source):
        fc = self.p.square_dot(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_square_pin(self, source):
        fc = self.p.square_pin(
            "x_values",
            "y_values",
            size="size_list",
            color="color_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            source=source,
        )
        return fc

    def plot_square_x(self, source):
        fc = self.p.square_x(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_star_default(self, source):
        fc = self.p.star(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_star_dot(self, source):
        fc = self.p.star_dot(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_triangle_default(self, source):
        fc = self.p.triangle(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_triangle_dot(self, source):
        fc = self.p.triangle_dot(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def plot_triangle_pin(self, source):
        fc = self.p.triangle_pin(
            "x_values",
            "y_values",
            size="size_list",
            fill_alpha="fill_alpha_list",
            line_alpha="line_alpha_list",
            color="color_list",
            source=source,
        )
        return fc

    def read_pop_color_map(self):
        """
        pop color map file contains three column: population id, shape, hex color code
        """
        with open(self.pop_color_map) as source:
            for line in source:
                line = line.rstrip().split()
                self.pop_color_dict[line[0]] = [line[2], line[1]]
        return self.pop_color_dict

    def generate_random_colr_shape(self):
        """
        generate random shape from the list of keys of shape_method_dict directory
        """
        num_pop = len(self.pop_color_dict)
        shape_list = []
        for i in range(num_pop):
            shape_select = random.choice(list(self.shape_method_dict.keys()))
            shape_list.append(shape_select)
        for i, v in enumerate(list(self.pop_color_dict.keys())):
            self.pop_color_dict[v].append(shape_list[i])

    def evec_to_cord_dict(self):
        with open(self.yaml_file, "r") as p:
            params = yaml.load(p, Loader=SafeLoader)
        self.pc1 = params["pc_x_to_plot"]
        self.pc2 = params["pc_y_to_plot"]
        self.width = params["plot_width"]
        self.height = params["plot_height"]
        self.show_sample_label = bool(params["show_sample_label"])
        self.title = params["title"]
        fill_alpha = params["fill_alpha"]
        line_alpha = params["line_alpha"]
        header = 0
        size = params["marker_size"]
        color_list = []  # created just to store the colors so that same color will not be assign to different populations
        with open(self.evec_file) as source:
            for line in source:
                line = line.rstrip().split()
                if header == 0:
                    header += 1
                else:
                    if line[-1] not in self.evec_dict:
                        if self.pop_color_map == "none":
                            color = ["#"+ "".join([random.choice("0123456789ABCDEF") for n in range(6)])][0]
                            while color in color_list:
                                color = [
                                    "#"
                                    + "".join(
                                        [
                                            random.choice("0123456789ABCDEF")
                                            for n in range(6)
                                        ]
                                    )
                                ][0]
                            color_list.append(color)
                            self.pop_color_dict[line[-1]] = [color]
                        self.evec_dict[line[-1]] = {
                            "x_values": [],
                            "y_values": [],
                            "sample_id": [],
                            "color_list": [],
                            "fill_alpha_list": [],
                            "line_alpha_list": [],
                            "size_list": [],
                        }
                    p_color = self.pop_color_dict[line[-1]][0][:]
                    self.evec_dict[line[-1]]["x_values"].append(float(line[self.pc1]))
                    self.evec_dict[line[-1]]["y_values"].append(float(line[self.pc2]))
                    self.evec_dict[line[-1]]["sample_id"].append(line[0])
                    self.evec_dict[line[-1]]["color_list"].append(p_color)
                    self.evec_dict[line[-1]]["fill_alpha_list"].append(fill_alpha)
                    self.evec_dict[line[-1]]["line_alpha_list"].append(line_alpha)
                    self.evec_dict[line[-1]]["size_list"].append(size)
        if self.pop_color_map == "none":
            self.generate_random_colr_shape()

    def eval_to_list(self):
        """
        read .eval file or file with the first column as the eigenvalue of each PC
        """
        self.eval_list = []
        with open(self.eval_file) as source:
            for line in source:
                line = line.strip().split()
                self.eval_list.append(line[0])

    def plot_evec(self):
        if self.pop_color_map != "none":
            self.read_pop_color_map()
        self.evec_to_cord_dict()
        self.eval_to_list()
        self.p = figure(width=self.width, height=self.height)
        self.p.output_backend = "svg"
        output_file(self.outprefix + ".html")
        legend_count = 0
        legend_list = []
        shift = 0
        for pop in self.evec_dict:
            legend_count += 1
            source = ColumnDataSource(data=self.evec_dict[pop])
            shape = self.pop_color_dict[pop][1]
            if self.show_sample_label:
                hover = HoverTool(tooltips=[("sample_id:", "@sample_id")])
                self.p.add_tools(hover)
            if legend_count >= 30:
                self.legend_loc_list.append(legend_list[:])
                legend_list = []
                legend_count = 0
            legend_list.append((pop, [self.shape_method_dict[shape](source)]))
        if len(legend_list) > 0:
            self.legend_loc_list.append(legend_list[:])
        for l_loc in self.legend_loc_list:
            shift += 3
            legend = Legend(items=l_loc, location=(0 - shift, -30 - shift))
            self.p.add_layout(legend, "right")
        self.p.legend.click_policy = "hide"
        self.p.legend.title = "population_id"
        self.p.xaxis.axis_label = (
            "PC" + str(self.pc1) + " ( " + self.eval_list[self.pc1 - 1] + " )"
        )
        self.p.yaxis.axis_label = (
            "PC" + str(self.pc2) + " ( " + self.eval_list[self.pc2 - 1] + " )"
        )
        save(self.p)


if __name__ == "__main__":
    plot_interactive_pca = PlotInteractivePca(
        sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
    )
    plot_interactive_pca.plot_evec()
