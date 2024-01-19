process SWEEPFINDER2{

    tag { "sweepfinder_input_${pop}" }
    label "process_single"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sweepfinder2:1.0--hec16e2b_4' :
        'biocontainers/sweepfinder2:1.0--hec16e2b_4' }"
    publishDir("${params.outdir}/selection/sweepfinder2/", mode:"copy")

    input:
        tuple val(meta), path( freqs ), path(afs), path( recomb )
        val(method)

    output:
        tuple val(meta), path ( "*.out" ), emit:pop_txt

    script:
        pop = meta.id
        if (method == "afs"){
            args = " -f "+freqs
            output = freqs.getName().minus(".freq")+"_afs.out"
        }
        else{
            output = freqs.getName().minus(".freq")+".out"
            if(params.grid_points > 0){
                args1 = "-"+method+" "+params.grid_points+ " "+freqs
            }
            else{
                args1 = "-"+method+"g "+params.grid_space+ " "+freqs
            }
            args2 = afs?:''
            args3 = recomb?:''
            args = args1+" "+args2+" "+args3
        }

        """
            SweepFinder2 ${args} ${output}

        """ 
}
