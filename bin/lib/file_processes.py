import numpy as np

"""
following method create the dictionary for the sample map file and list of the pop name, it should have the following format:

sample1 pop1
sample2 pop1
sample3 pop1
sample4 pop2
sample5 pop2

note that sample name should match with that defined in the vcf header (look for the line starting with "#CHROM")
delimiter is blank space/tab.

output
mode 0 --> dictionary--> sample_pop_dict={"sample 1":"pop1","sample2";"pop1",.,.}
mode 1 list --> pop_list=[sample1,sampl2,sample3,sample4]

"""


def prepare_sample_pop_dict(file_in, mode):
    pop_list = []
    sample_pop_dict = {}
    with open(file_in) as source:
        for line in source:
            line = line.rstrip().split()
            sample_pop_dict[line[0]] = line[1]
            if line[1] not in pop_list and mode == 1:
                pop_list.append(line[1])
    return_item = pop_list if mode == 1 else sample_pop_dict
    return return_item


"""

following method will return the string with the output for the sample dict (self.sample_local_window_dict)

"""


def write_sample_dict(sample_local_window_dict):
    str_out_sample = ""
    for sample in sample_local_window_dict:
        str_out_sample += "\t"
        value_list = list(sample_local_window_dict[sample].values())
        value_list[5] = value_list[5] / max(1, int(value_list[4]))
        value_list = list(map(str, value_list))
        str_out_sample += "\t".join(value_list)
    return str_out_sample


"""

following method will return the string with the output for the pop dict (self.sample_local_window_dict)

"""


def write_pop_dict(pop_local_window_dict):
    str_out_pop = ""
    for pop in pop_local_window_dict:
        str_out_pop += "\t"
        value_list = list(pop_local_window_dict[pop].values())
        total_snps = value_list[4]
        value_list.remove(value_list[4])
        value_list = np.array(list(map(float, value_list))) / int(total_snps)
        value_list = list(map(str, value_list))
        value_list.insert(4, str(total_snps))
        str_out_pop += "\t".join(list(value_list))
    return str_out_pop


"""

following method create the output dictionary for sample or populations, mode 0 --> sample_list, mode 1 --> pop_list

self.params_list=[(0, 0),(0, 1),(1, 1),"missing_geno","total_snps","average_depth","average_obs_het","ts","tv"]

structure --> {"sample1":{(0,0):0,(0,1):0,(1,1):0,"missing_geno":0,"total_snps":0,"average_depth":0,"average_obs_het":0,"ts":0,"tv":0}}

"""


def prepare_sample_param_dict(sample_list, params_list, mode):
    sample_param_dict = {}
    for sample in sample_list:
        sample_param_dict[sample] = {}
        for params in params_list:
            sample_param_dict[sample][params] = 0
        if mode == 1:
            sample_param_dict[sample]["MAF"] = 0
    return sample_param_dict
