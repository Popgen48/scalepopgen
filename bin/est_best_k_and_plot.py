import sys
import re
import pandas as pd
from bokeh.models.tools import Tool
import numpy as np
from collections import OrderedDict
from scipy.signal import argrelextrema
from bokeh.plotting import figure, save, output_file
from bokeh.models import HoverTool, ColumnDataSource, Legend
from bokeh.models.tickers import FixedTicker

def main_function(type_minima, file_list):
    cv_value_dict = OrderedDict()
    cv_value_list_sorted = []
    k_value_list_sorted = []
    for file_name in file_list:
        with open(file_name) as source:
            for line in source:
                if line.startswith("CV"):
                    line = line.rstrip()
                    pattern = re.compile("CV error \(K=([0-9]+)\):\s+(.*)")
                    match = re.findall(pattern, line)
                    k_value = int(match[0][0])
                    cv_value = float(match[0][1])
                    cv_value_dict[k_value] = cv_value
    for i in range(
        min(list(cv_value_dict.keys())), max(list(cv_value_dict.keys())) + 1
    ):
        k_value_list_sorted.append(i)
        cv_value_list_sorted.append(cv_value_dict[i])
    try:
        local_minima_list = list(
            argrelextrema(np.array(cv_value_list_sorted), np.less)
        )[0]
        if type_minima == "local":
            minima_idx = local_minima_list[0]
        elif type_minima == "global":
            minima_idx = cv_value_list_sorted.index(
                min([cv_value_list_sorted[i] for i in local_minima_list])
            )
        best_k = k_value_list_sorted[minima_idx]
        best_cv = cv_value_list_sorted[minima_idx]
        p = figure(width=800, height=800)
        p.output_backend = "svg"
        output_file("best_k_" + str(best_k) + ".html")
        lst_df = [
            [v, cv_value_list_sorted[i]] for i, v in enumerate(k_value_list_sorted)
        ]
        pd1 = pd.DataFrame(lst_df, columns=["k", "cross_validation_error"])
        source = ColumnDataSource(pd1)
        p.line("k", "cross_validation_error", source = source)
        p.circle("k","cross_validation_error", source = source)
        p.xaxis.ticker = FixedTicker(ticks=k_value_list_sorted)
        hover = HoverTool(
            tooltips=[("cross_validation_error", "@cross_validation_error")]
        )
        p.add_tools(hover)
        p.xaxis.axis_label = "values of K"
        p.yaxis.axis_label = "cross validation error"
        save(p)
    except:
        print(
            "the function could not find "
            + type_minima
            + " minima, use even greater k-values than "
            + str(max(k_value_list_sorted))
            + " for admixture analysis"
        )
        sys.exit(1)


if __name__ == "__main__":
    main_function(sys.argv[1], sys.argv[2:])
