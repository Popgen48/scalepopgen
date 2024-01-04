###import the necessary modules
"""
sys --> for exiting gracefully
argparse ---> add the options to the script
pysam --> reading vcf file

"""
import sys
import argparse
import re
import gzip
import numpy as np
from pysam import VariantFile
from lib.calcWcFst import CalcFst
from lib.file_processes import populateSampleDict
from lib.vcf_to_chrom_windows import VcfToChromCords
from lib.vcf_stats import VcfStats
from lib.vcf_to_treemix import VcfToTreemix

if __name__ == "__main__":
    VCF_STATS = "vcfstats"
    CONVERT_TREEMIX = "convert2treemix"

    parser = argparse.ArgumentParser(
        description="get various individual and population based summary statistics from vcf file",
        epilog="author: Maulik Upadhyay (Upadhyaya.maulik@gmail.com)",
    )
    subparsers = parser.add_subparsers(help="sub-command help", dest="command")

    vcf_stats_parser = subparsers.add_parser(
        VCF_STATS,
        help="get various sampled-based and population-based summary statistics from vcf file",
    )
    vcf_stats_parser.add_argument(
        "-v", "--vcfF", metavar="File", help="vcf file", required=True
    )
    vcf_stats_parser.add_argument(
        "-m", "--sampleF", metavar="File", help="sample map file", required=True
    )
    vcf_stats_parser.add_argument(
        "-w",
        "--window",
        metavar="Int",
        help="window size for statistics and fst",
        default=999999999,
        required=False,
    )
    vcf_stats_parser.add_argument(
        "-s",
        "--step",
        metavar="Int",
        help="window step size for statistics and fst",
        default=1,
        required=False,
    )
    vcf_stats_parser.add_argument(
        "-o", "--outPrefix", metavar="Str", help="prefix of output file", required=True
    )
    vcf_stats_parser.add_argument(
        "-r",
        "--region",
        metavar="Str",
        help="region in format chr:start-end",
        default="NA",
        required=False,
    )
    vcf_stats_parser.add_argument(
        "-bI",
        "--bedIncl",
        metavar="Int",
        help="region to include",
        default="NA",
        required=False,
    )
    vcf_stats_parser.add_argument(
        "-bE",
        "--bedExcl",
        metavar="Int",
        help="region to exclude",
        default="NA",
        required=False,
    )

    convert_treemix_parser = subparsers.add_parser(
        CONVERT_TREEMIX, help="convert vcf to treemix input"
    )
    convert_treemix_parser.add_argument(
        "-v", "--vcfF", metavar="File", help="vcf file", required=True
    )
    convert_treemix_parser.add_argument(
        "-m", "--sampleF", metavar="File", help="sample map file", required=True
    )
    convert_treemix_parser.add_argument(
        "-o", "--outPrefix", metavar="Str", help="prefix of output file", required=True
    )
    convert_treemix_parser.add_argument(
        "-r",
        "--region",
        metavar="Str",
        help="region in format chr:start-end",
        default="NA",
        required=False,
    )
    convert_treemix_parser.add_argument(
        "-bI",
        "--bedIncl",
        metavar="File",
        help="regions to include",
        default="NA",
        required=False,
    )
    convert_treemix_parser.add_argument(
        "-bE",
        "--bedExcl",
        metavar="File",
        help="regions to exclude",
        default="NA",
        required=False,
    )

    args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    elif args.command == VCF_STATS:
        vcfstats = VcfStats(
            args.vcfF,
            args.sampleF,
            args.window,
            args.step,
            args.outPrefix,
            args.region,
            args.bedIncl,
            args.bedExcl,
        )
        vcfstats.writeVcfStats()
    elif args.command == CONVERT_TREEMIX:
        vcftotreemix = VcfToTreemix(
            args.vcfF,
            args.sampleF,
            args.region,
            args.bedIncl,
            args.bedExcl,
            args.outPrefix,
        )
        vcftotreemix.convertToTreemix()
