import sys
import pandas as pd
import numpy as np

window_size = sys.argv[1]
sel_threshold    = sys.argv[2]
method = sys.argv[3]
outprefix = sys.argv[4]
files = sys.argv[5:]

df = pd.DataFrame()


for file in files:
    df1 = pd.read_csv(file,delim_whitespace=True,index_col=False)
    df = pd.concat([df, df1], ignore_index=True)

df.sort_values(['CHROM', 'BIN_START'], ascending=[True, True], inplace=True)

if method == "tajimas_d":
    df["BIN_END"] = df["BIN_START"]+int(window_size)
    df["BIN_START"] = df["BIN_START"]+1
    col_name = "TajimaD"

if method == "fst":
    col_name = "MEAN_FST"

if method == "pi":
    col_name = "PI"

f_df = df[["CHROM","BIN_START","BIN_END",col_name]]

f_df.replace(np.nan, 0, inplace=True)

if method == "fst":
    f_df[col_name] = f_df[col_name].apply(lambda x : x if x > 0 else 0)

merge_df = f_df.to_csv(outprefix+".out",sep=" ",header=True,index=False)


with open(outprefix+".cutoff","w") as dest:
    cutoff = 1-float(sel_threshold) if method == "fst" else float(sel_threshold)
    dest.write("id"+","+"cutoff"+"\n")
    dest.write(outprefix+","+str(f_df[col_name].quantile(cutoff))+"\n")
