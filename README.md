[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

# consprot

Delineate bacterial genera quickly and transparently using the Percentage Of Conserved Proteins (POCPu) using a validated nextflow workflow

## Usage

```bash
consprot run --input <directory of genomes> --output <name of output directory>
```

`consprot` will run a nextflow workflow locally and compute POCPu values for all pairwise comparisons (except self-comparisons). This means that adding `-resume` will reuse cached results and only rerun what changed (e.g., additional genomes):

```bash
consprot run --input <directory of genomes> --output <name of output directory> -resume
```

### Input

A directory with genome files (`.fa`, `.fna` or `.fasta`).

Upcoming:

- Protein files if already available and/or to bypass pyrodigal
- List of files to bypass nextflow file search

### Output

The specified output directory will contain a `pocpu.csv` with the following columns:

- `query`: basename of the genome used in this comparison
- `subject`: basename of the genome used in this comparison
- `pocp`: value of legacy POCP [0-100]. Could exceed 100 in case of duplicated genes. 
- `pocpu`: value of POCPu [0-100] using only unique matches. 

Note: nextflow workflow produce additional files and directory where it is ran. For instance, the log file of the latest run is `.nextflow.log`, or the working directory with temporary files is `work`.

## Installation

At the moment, install `consprot` by cloning the repository and follow the development section.


Upcoming: bioconda

## Development

To build `consprot` safely, work in a separate conda environment and install using the dedicated pip:

```bash
mamba create -n consprot-dev python pip
conda activate consprot-dev
python -m pip install -e .
consprot -v
```
