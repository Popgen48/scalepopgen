import sys
import pandas as pd
import numpy as np

window_size = sys.argv[1]
method = sys.argv[2]
output_file = sys.argv[3]
files = sys.argv[4:]

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

merge_df = f_df.to_csv(output_file,sep=" ",header=True,index=False)
