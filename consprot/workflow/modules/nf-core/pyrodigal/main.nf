process PYRODIGAL {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-2fe9a8ce513c91df34b43a6610df94c3a2eb3bd0:47e7d40834619419f202394563267d74cef857be-0':
        'biocontainers/mulled-v2-2fe9a8ce513c91df34b43a6610df94c3a2eb3bd0:47e7d40834619419f202394563267d74cef857be-0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.faa.gz")                   , emit: faa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pyrodigal \\
        $args \\
        -i ${fasta} \\
        -a ${prefix}.faa

    pigz -nmf ${prefix}*
    """
}
