import numpy as np

class CalcFst:

    def __init__(self,inputDict):
        self.tmpPopDict=inputDict
        self.popAlleleFreqDict={}
        self.genoList={(0,0):0,(0,1):1,(1,1):2}
        self.popList=list(inputDict.keys())
        self.fstStr=""

    def __str__(self):
        self.createInputFst()
        self.calcFstats()
        return str(self.fstStr)

    def createInputFst(self):
        for pop in self.tmpPopDict:
            samplesPerPop=[self.tmpPopDict[pop][geno] for geno in self.genoList]
            numPop=max(1,sum(samplesPerPop))
            self.popAlleleFreqDict[pop]=[(self.tmpPopDict[pop][(0, 1)]*1+self.tmpPopDict[pop][(1, 1)]*2)/(2*numPop),numPop,self.tmpPopDict[pop][(0, 1)]]

    def calcFstats(self):
        popAlleleFreq=[self.popAlleleFreqDict[i][0] for i in self.popAlleleFreqDict]
        popSampleSize=[self.popAlleleFreqDict[i][1] for i in self.popAlleleFreqDict]
        popObsHet=[self.popAlleleFreqDict[i][2] for i in self.popAlleleFreqDict]
        fst="NaN"
        fstList=[]
        for popIdx1 in range(len(self.popList)):
            for popIdx2 in range(popIdx1+1,len(self.popList)):
                n1=popSampleSize[popIdx1]
                n2=popSampleSize[popIdx2]
                p1=popAlleleFreq[popIdx1]
                p2=popAlleleFreq[popIdx2]
                if (n1>0 and n2>0) and (p1!=0 or p2!=0):
                    het1=popObsHet[popIdx1]
                    het2=popObsHet[popIdx2]
                    h_bar=(het1+het2)/(n1+n2)
                    n_bar=(n1+n2)/2
                    n_c=(n1+n2)-((n1*n1+n2*n2)/(n1+n2))
                    p_bar=(n1*p1)/(n1+n2)+(n2*p2)/(n1+n2)
                    s_square=(n1*(p1-p_bar)*(p1-p_bar)+n2*(p2-p_bar)*(p2-p_bar))/n_bar
                    if n_bar!=1 and p_bar!=1:
                        a=(n_bar/n_c)*(s_square-1/(n_bar-1)*(p_bar*(1-p_bar)-(s_square/2)-((1/4)*h_bar)))
                        b=(n_bar/(n_bar-1))*(p_bar*(1-p_bar)-s_square/2-((2*n_bar-1)/(4*n_bar))*h_bar)
                        c=h_bar/2
                        if (a+b+c)!=0:
                            fst=(a/(a+b+c))
                fstList.append(str(fst))
        self.fstStr="\t".join(fstList)+"\n"
