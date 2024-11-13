process DIAMOND_MAKEDB {
   tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/diamond:2.1.8--h43eeafb_0' :
        'biocontainers/diamond:2.1.8--h43eeafb_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.dmnd"), emit: db

    when:
    task.ext.when == null || task.ext.when

    script:
    def args              = task.ext.args ?: ''
    def prefix            = task.ext.prefix ?: "${meta.id}"
    def is_compressed     = fasta.getExtension() == "gz" ? true : false
    def fasta_name        = is_compressed ? fasta.getBaseName() : fasta

    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    diamond \\
        makedb \\
        --threads ${task.cpus} \\
        --in  ${fasta_name} \\
        -d ${prefix} \\
        ${args}
    """
}
