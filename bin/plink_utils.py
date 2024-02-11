from collections import OrderedDict


def read_color_map_file(color_file):
    pop_color_dict = OrderedDict()
    with open(color_file) as source:
        for line in source:
            line = line.rstrip().split()
            pop_color_dict[line[0]] = line[2]
    return pop_color_dict


def read_bim_file(bim, window_size):
    bim_dict = OrderedDict()
    first_record = True
    first_pos = 0
    first_chrom = "not_set"
    wc = 0 # window count
    rc = 0 # record count
    with open(bim) as source:
        for line in source:
            line = line.rstrip().split()
            rc += 1
            if first_record:
                wc += 1
                first_pos = int(line[3])
                first_record = False
            elif (
                first_pos + int(window_size) >= int(line[3]) and line[0] == first_chrom # check if the chromosome in the previous record and the current record is also same 
            ):
                pass
            else:
                wc += 1
                first_pos = int(line[3])
            first_chrom = line[0]
            bim_dict[rc] = wc
        bim_dict[rc] = wc
    return bim_dict
