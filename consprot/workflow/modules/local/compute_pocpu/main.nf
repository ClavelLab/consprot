process COMPUTE_POCPU {
    tag "POCPu"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'biocontainers/pandas:2.2.1' }"

    input:
    path proteins
    path matches

    output:
    path "pocpu.csv", emit: csv

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    #!/usr/bin/env python3
    import pandas as pd
    # Read the table and have total proteins as dict()
    proteins_counts=pd.read_csv("${proteins}",index_col=0)
    total_proteins=proteins_counts['Sequences'].to_dict()

    # Read the count of matches
    comparisons = pd.read_csv("${matches}",
                              dtype={
                                  "id": str,
                                  "n_matches": float,
                                  "n_unique_matches": float
                              })

    # Split the id to extract the relevant identifiers: query, subject
    comparisons[["query", "subject"]] = comparisons["id"].str.split("--", expand=True)

    # Add the total count of proteins
    comparisons["query_proteins"] = comparisons["query"].map(total_proteins)
    comparisons["subject_proteins"] = comparisons["subject"].map(total_proteins)

    # For each row, create an identifier (query-subject) for(query-subject *and* subject-query)
    comparisons["comparison_id"] = comparisons.apply(
        lambda row: "--".join(sorted([row["query"], row["subject"]])), axis=1
    )

    # Compute the percentage of conserved proteins (POCP) between two genomes
    comparisons = comparisons.groupby("comparison_id").apply(
        lambda x: pd.Series({
        "pocp": 100 * (x["n_matches"].sum() / (x["query_proteins"].sum() + x["subject_proteins"].sum())),
        "pocpu": 100 * (x["n_unique_matches"].sum() / (x["query_proteins"].sum() + x["subject_proteins"].sum()))
    }), include_groups=False).reset_index()

    # Remove redundant rows, keep only one for two comparisons
    comparisons = comparisons.drop_duplicates()

    # Arrange by comparison_id and write to csv
    comparisons = comparisons.sort_values(by="comparison_id")
    comparisons[["query","subject"]] = comparisons["comparison_id"].str.split("--", n = 1, expand = True)
    comparisons = comparisons[['query','subject', 'pocp', 'pocpu']]
    comparisons.to_csv("pocpu.csv", index=False)
    """
}
