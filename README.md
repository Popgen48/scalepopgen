[![GitHub Actions CI Status](https://github.com/popgen48/scalepopgen/workflows/nf-core%20CI/badge.svg)](https://github.com/popgen48/scalepopgen/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/popgen48/scalepopgen/workflows/nf-core%20linting/badge.svg)](https://github.com/popgen48/scalepopgen/actions?query=workflow%3A%22nf-core+linting%22)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/popgen48/scalepopgen)

## Introduction

**scalepopgen** is a fully automated nextflow-based pipeline that takes **VCF** or **PLINK binary** files as input and apply a variety of open-source tools to carry out comprehensive population genomic analyses. Additionally, python and R scripts have been developed to combine and plot the results of analyses, which allows user to immediately get an impression about the genomic patterns of the analyzed samples. 

<p>Broadly, the pipeline consists of the following four “sub-workflows”:</p>
<ul>
<li>filtering and basic statistics</li>
<li>explore genetic structure</li>
<li>phylogeny using treemix</li>
<li>signatures of selection</li>
</ul>
<p>The sub-workflows can be used separately or in combination with each other.</p>

The pipeline can be run on any Linux operating system and require these three dependencies: Nextflow, Java and a software container or environment system such as `conda`, `mamba`, `singularity` or `docker`. Regarding the latter, we highly recommend using `mamba`. The pipeline can be run on both, local linux system as well as high performance computing (HPC) clusters. Note that the user only install the three dependencies listed above, while Nextflow automatically downloads the rest of the tools for the analyses.

## Usage

::: note
If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up the Nextflow. Please, make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.
:::

After successful installation of Nextflow, Java and one of the container systems, download the scalepopgen:

```
git clone https://github.com/Popgen48/scalepopgen_v1.git
```

#### INPUT FILES

All VCF files need to be splitted by the chromosomes and indexed with tabix. The VCF inputs should be listed in the comma-separated input sheet with the extension ".csv" and the header row exactly like in the example below. Please note that the chromosome name must not contain any punctuation marks.

**vcf_input.csv:**
```
chrom,vcf,vcf_idx
chr1,chrom1.vcf.gz,chrom1.vcf.gz.tbi
chr2,chrom2.vcf.gz,chrom2.vcf.gz.tbi
```
In addition to the VCF input format, it is also necessary to prepare a sample map file of individuals and populations. Sample map has two tab-delimited columns without header line. In the first column are individual IDs and in the second are population IDs as demonstrated on the example below. It is also important that the name of the file ends with ".map".

**sample.map:**
```
ind1  pop1
ind2  pop1
ind3  pop2
ind4  pop2
```

Similarly for the PLINK binary files, user need to specify them in the comma-separated input sheet with the header row, but with the extension ".p.csv".

**plink_input.csv:**
```
prefix,bed,bim,fam
popgen,popgen.bed,popgen.bim,popgen.fam
```


The workflow implement a lot of programs and tools, which consequently means a lot of parameters that need to be determined and provided as the yml format file. In order to make it easier for the users, we developed a Command-Line Interface (CLI), which helps to specify options for each sub-workflow. In fact, we highly recommend the CLI for creating parameter file as it guides the user through various options and at the same time checks the input formats.

The CLI can be downloaded and installed with the following commands:

```
git clone https://github.com/Popgen48/scalepopgen-cli.git
cd scalepopgen-cli/
#pip install --upgrade pip --> to update the version of pip 
pip3 install --no-cache-dir -r requirements.txt --user
```

Start the CLI with:
```
python scalepopgen_cli.py
```
![grafik](https://github.com/Popgen48/scalepopgen_v1/assets/131758840/1e853c26-404d-43d5-b3fb-d7a1c9e879d4)

Navigate through different sub-workflows and their options.

![grafik](https://github.com/Popgen48/scalepopgen_v1/assets/131758840/96936bd8-a3d6-46e9-814a-5119ef0eee4a)
![grafik](https://github.com/Popgen48/scalepopgen_v1/assets/131758840/d980e7bb-cddf-478a-9849-db40dd96c399)


Once you select and specify the parameters according to analyses you want to perform, simply save them to yml file and copy the path within the `-params-file` option.

![grafik](https://github.com/Popgen48/scalepopgen_v1/assets/131758840/c2dfc4fd-032d-4241-8499-a233bf378216)


Now, you can run the scalepopgen:

```bash
nextflow run popgen48/scalepopgen \
   -profile <docker/singularity/conda/mamba> \
   -params-file <path/to/parameters.yml> \
   -qs <maximum number of processes>
```

::: warning
Custom config files, including those provided by the Nextflow option `-c`, can be used to provide any other configuration, _**except for the parameters**_;
see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).
:::

## Credits

**scalepopgen** was originally written by @BioInf2305 with small contributions from @NPogo.

Many thanks to `nf-core` community for their assistance and help in the development of this pipeline.

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  popgen48/scalepopgen for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
