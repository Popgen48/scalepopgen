library("OptM")
library("optparse")
args=commandArgs(TRUE)


run_optM=function(dir_name, method_name, out_prefix){
    	   out_pdf=paste(out_prefix,".pdf",sep="")
	   out_tsv=paste(out_prefix,".tsv",sep="")
	   results = optM(dir_name, tsv = out_tsv)
	   plot_optM(results, method= method_name, plot= FALSE, pdf=out_pdf)
}

option_list = list(
		     make_option(c("-d", "--dir"), type="character", default=NULL, 
				               help="prefix of plink bed file", metavar="character"),
		     make_option(c("-m", "--methd"), type="character", default="Evanno", 
				      help="use one from Evanno, linear, SiZer [default= %default]", metavar="character"),
		     make_option(c("-o", "--out"), type = "character", help="output prefix", default = "OptM_results", metavar = "character")
		     ); 

opt_parser = OptionParser(option_list=option_list);

opt = parse_args(opt_parser);

if (is.null(opt$dir)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file)", call.=FALSE)
}

run_optM(opt$dir, opt$methd, opt$out)

