###import the necessary modules
"""
sys --> for exiting gracefully
argparse ---> add the options to the script

"""
import sys
import argparse
import re
import gzip
from pysam import VariantFile
from collections import OrderedDict
from lib.file_processes import populateSampleDict
from lib.vcf_to_chrom_windows import VcfToChromCords


class VcfToTreemix:


    def __init__(self,vcfIn,sampleMap,regionIn,bedIn,bedEx,outPrefix):

        self.vcfFileName=vcfIn
        self.vcfIn = VariantFile(vcfIn)
        self.sampleMap = sampleMap
        self.regionIn = regionIn
        self.bedIn = bedIn
        self.bedEx = bedEx
        self.outPrefix = outPrefix



    def convertToTreemix(self):
        popList, samplePopDict = populateSampleDict(self.sampleMap)
        vcf_to_chrom_cords = VcfToChromCords(self.vcfFileName,self.bedIn,self.bedEx,self.regionIn,99999999999999999999,1)
        chromWindowDict = vcf_to_chrom_cords.populateChromDict()
        dest=gzip.open(self.outPrefix+"_treemixIn.gz",'wb')
        dest.write(" ".join(popList).encode())
        for chrom in chromWindowDict:
            chromCordIntervals = chromWindowDict[chrom]
            for cordInterval in chromCordIntervals:
                print(chrom,cordInterval)
                for rec in self.vcfIn.fetch(chrom,int(cordInterval[0]),int(cordInterval[1])):
                    dest.write("\n".encode())
                    treemixDict=OrderedDict()
                    refAllele=0
                    altAllele=0
                    for pop in popList:
                        treemixDict[pop]=[0,0]
                    for sample in samplePopDict:
                        gt=rec.samples[sample]["GT"]
                        treemixDict[samplePopDict[sample]][0]+=gt.count(0)
                        treemixDict[samplePopDict[sample]][1]+=gt.count(1)
                        refAllele+=gt.count(0)
                        altAllele+=gt.count(1)
                    for pop in treemixDict:
                        if refAllele>=altAllele:
                            writeRecord=str(treemixDict[pop][0])+","+str(treemixDict[pop][1])
                        else:
                            writeRecord=str(treemixDict[pop][1])+","+str(treemixDict[pop][0])
                        dest.write(writeRecord.encode())
                        dest.write(" ".encode())
        dest.close()
