process COUNT_PROTEINS {
   tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), path(dbinfo)

    output:
    tuple val(meta), path("count_proteins.csv"), emit: csv

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix            = task.ext.prefix ?: "${meta.id}"

    """
    #!/usr/bin/env python3
    import pandas as pd
    dbinfo=pd.read_table("${dbinfo}",
        sep="\s\s", engine="python", index_col=0)
    count_proteins=pd.DataFrame(dbinfo.loc["Sequences"])

    count_proteins.rename(
        index={'Diamond database':"${prefix}"}
    ).to_csv("count_proteins.csv")
    """
}
