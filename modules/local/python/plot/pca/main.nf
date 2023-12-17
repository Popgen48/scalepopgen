process PYTHON_PLOT_PCA{

    tag { "plot_interactive_pca" }
    label "oneCpu"
    conda "${moduleDir}/environment.yml"
    container "popgen48/plot_pca:1.0.0"
    publishDir("${params.outdir}/genetic_structure/interactive_plots/pca/", mode:"copy")

    input:
        tuple val(meta), path(eigenvect)
        tuple val(meta), path(eigenval)
        path(m_pop_sc_col)
        path(pca_plot_yml)
        path(marker_map)

    output:
        path("*.html")
        path("*.log")
        path("pop_markershape_col.txt")
        

    when:
        task.ext.when == null || task.ext.when

    script:
        
        prefix = meta.id
        def args = task.ext.args ?: ''


        if (marker_map == []){

	"""

        awk 'NR==FNR{markershape[NR]=\$0;next}{col_cnt=int(rand() * 20)+5;print \$1,markershape[col_cnt],\$3}' ${baseDir}/extra/markershapes.txt ${m_pop_sc_col} > pop_markershape_col.txt

        python ${baseDir}/bin/plot_interactive_pca.py ${eigenvect} ${eigenval} pop_markershape_col.txt ${pca_plot_yml} ${prefix}

        cp .command.log plot_interactive_pca_${prefix}.log

	"""

        }
        else{

	"""

        awk 'NR==FNR{markershape[\$1]=\$2;next}{print \$1,markershape[\$1],\$3}' ${f_pop_marker} ${m_pop_sc_col} > pop_markershape_col.txt

        python ${baseDir}/bin/plot_interactive_pca.py ${eigenvect} ${eigenval} pop_markershape_col.txt ${pca_plot_yml} ${prefix}
        
        cp .command.log plot_interactive_pca_${prefix}.log

	"""

        }
}
