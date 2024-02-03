process PDF2HTML{

    tag { "${outprefix}" }
    label "process_single"
    publishDir("${params.outdir}/treemix/pdf2html/", mode:"copy")

    input:
        path(pdf)

    output:
    	path("*_mqc.html"), emit: html

    when:
     	task.ext.when == null || task.ext.when

    script:
        outprefix = pdf.getName().minus(".pdf")
        
        
        """

        wget https://github.com/pdf2htmlEX/pdf2htmlEX/releases/download/v0.18.8.rc1/pdf2htmlEX-0.18.8.rc1-master-20200630-Ubuntu-bionic-x86_64.AppImage
    
        chmod +x pdf2htmlEX-0.18.8.rc1-master-20200630-Ubuntu-bionic-x86_64.AppImage

        mv pdf2htmlEX-0.18.8.rc1-master-20200630-Ubuntu-bionic-x86_64.AppImage ${baseDir}/bin/pdf2html 
        
        ${baseDir}/bin/pdf2html ${pdf} ${outprefix}.html

        cat ${baseDir}/assets/treemix_comments.txt ${outprefix}.html > ${outprefix}_mqc.html

	""" 
        

}
