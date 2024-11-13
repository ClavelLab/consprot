[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

# consprot

Delineate bacterial genera quickly and transparently using the Percentage Of Conserved Proteins (POCPu) using a validated nextflow workflow

## Development

To build `consprot` safely, work in a separate conda environment and install using the dedicated pip:

```bash
mamba create -n consprot-dev python pip
conda activate consprot-dev
python -m pip install -e .
consprot -v
```
