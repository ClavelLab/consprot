process DIAMOND_DBINFO {
   tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/diamond:2.1.8--h43eeafb_0' :
        'biocontainers/diamond:2.1.8--h43eeafb_0' }"

    input:
    tuple val(meta), path(db)

    output:
    tuple val(meta), path("*.out"), emit: out

    when:
    task.ext.when == null || task.ext.when

    script:
    def args              = task.ext.args ?: ''
    def prefix            = task.ext.prefix ?: "${meta.id}"

    """
    diamond \\
        dbinfo --db ${db} > ${prefix}.out
    """
}
