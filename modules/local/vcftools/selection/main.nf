process VCFTOOLS_SELECTION{

    tag { "vcftools_${method}_${chrom}" }
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://popgen48/vcftools_bgzip:0.1.16_1.19.1' :
        'popgen48/vcftools_bgzip:0.1.16_1.19.1' }"
    publishDir("${params.outdir}/selection/vcftools/${method}/${pop1}/${chrom}", mode:"copy")

    input:
        tuple val(meta), path(vcf), path(file1), path(file2)
        val(method)

    output:
        tuple val(pop1), path ("*${outprefix}*"), emit: txt
        path "versions.yml", emit: versions

    script:
        chrom=meta.id
        pop1 = file1.getName().minus(".txt")
        pop2 = (method=="pairwise_fst" || method=="fst_all") ? file2.getName().minus(".txt"):""
        outprefix = (method=="tajimas_d" || method=="pi_val" || method=="fst_all") ? chrom+"_"+pop1:chrom+"_"+pop1+"_"+pop2
        w = params.window_size
        s = params.step_size

        window = (method=="tajimas_d" || method=="pi_val") ? (method=="tajimas_d" ? " --TajimaD "+w:" --window-pi "+w) :" --fst-window-size "+w

        step_size = (method=="pi_val" || method=="pairwise_fst" || method=="fst_all") ? (method=="pi_val" ? " --window-pi-step "+s:" --fst-window-step "+s):''
        
        args = (method=="pairwise_fst" || method=="fst_all") ? " --weir-fst-pop "+ file1 + " --weir-fst-pop "+file2+ " --out "+outprefix : " --keep "+file1+ " --out "+outprefix

        """

    vcftools --gzvcf ${vcf} ${window} ${step_size} ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS


        """ 
}
