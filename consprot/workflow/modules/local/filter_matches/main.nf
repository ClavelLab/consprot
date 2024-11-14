process FILTER_MATCHES {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), path(diamond_matches)

    output:
    tuple val(meta), path("${meta.id}.csv"), emit: csv

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix            = task.ext.prefix ?: "${meta.id}"

    """
    #!/usr/bin/env python3
    import pandas as pd
    # Read the table
    df = pd.read_table("${diamond_matches}", sep = "\t",
                     names=[
                         "qseqid", "sseqid", "pident", "length",
                         "mismatch", "gapopen", "qstart", "qend",
                         "sstart", "send", "evalue", "bitscore"
                     ],
                     dtype={
                         "qseqid": str,
                         "sseqid": str,
                         "pident": float,
                         "length": float,
                         "mismatch": float,
                         "gapopen": float,
                         "qstart": float,
                         "qend": float,
                         "sstart": float,
                         "send": float,
                         "evalue": float,
                         "bitscore": float
                     })

    # Filter the values
    if df.empty:
        n_matches = 0
        n_unique_matches = 0
    else:
        # Count matches for POCP and unique matches for POCPu
        matches = df[df['pident'] > 40]
        n_unique_matches = matches['qseqid'].nunique()
        n_matches = len(matches.index)

    #  Write counts to csv
    pd.DataFrame({
        'id': ["${prefix}"],
        'n_matches': [n_matches],
        'n_unique_matches': [n_unique_matches]
    }).to_csv("${prefix}.csv", index=False)
    """
}
