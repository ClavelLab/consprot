"""
Entrypoint for consprot

Check out the wiki for a detailed look at customising this file:
https://github.com/beardymcjohnface/Snaketool/wiki/Customising-your-Snaketool
"""

import os
import click
from .util import (
    nek_base,
    get_version,
    copy_config,
    OrderedCommands,
    run_nextflow,
    print_citation,
)


def common_options(func):
    """Common options decorator for use with click commands."""
    options = [
        click.option(
            "--paramsfile",
            default="params.yaml",
            help="Custom params file",
            show_default=True,
        ),
        click.option(
            "--configfile",
            default="nextflow.config",
            help="Custom config file",
            show_default=True,
        ),
        click.option(
            "--threads", help="Number of threads to use", default=1, show_default=True
        ),
        click.option(
            "--use-conda/--no-use-conda",
            default=True,
            help="Use conda for Nextflow processes",
            show_default=True,
        ),
        click.option(
            "--conda-frontend",
            type=click.Choice(["mamba", "conda"], case_sensitive=True),
            default="mamba",
            help="Specify Conda frontend",
            show_default=True,
        ),
        click.option(
            "--conda-prefix",
            default=nek_base(os.path.join("workflow", "conda")),
            help="Custom conda env directory",
            type=click.Path(),
            show_default=False,
        ),
        click.argument("nextflow_args", nargs=-1),
    ]
    for option in reversed(options):
        func = option(func)
    return func


@click.group(
    cls=OrderedCommands, context_settings=dict(help_option_names=["-h", "--help"])
)
@click.version_option(get_version(), "-v", "--version", is_flag=True)
def cli():
    """Delineate bacterial genera quickly and transparently using the Percentage Of Conserved Proteins (POCPu) using a validated nextflow workflow
    \b\b
    For more options, run:
    consprot command --help"""
    pass


help_msg_extra = """
\b
CLUSTER EXECUTION:
consprot run ... -profile [profile],[profile],...
For information on Nextflow config and profiles see:
https://www.nextflow.io/docs/latest/config.html#config-profiles
\b
RUN EXAMPLES:
Required:           consprot run --input [file]
Specify threads:    consprot run ... --threads [threads]
Enable conda:       consprot run ... --use-conda
Add NextFlow args:  consprot run ... -work-dir workDir -with-docker
"""


@click.command(
    epilog=help_msg_extra,
    context_settings=dict(
        help_option_names=["-h", "--help"], ignore_unknown_options=True
    ),
)
@click.option("--input", "_input", help="Directory of genomes. Only files ending in *.fa, *.fna, *.fasta are considered.",
        type=click.Path(exists=True, dir_okay=True, file_okay=False), required=True)
@click.option("--output", "_output", help="Name for output directory. Path accepted.",
        type=click.Path(), required=True)
@common_options
def run(_input, _output, **kwargs):
    """Run consprot"""
    # Config to add or update in configfile
    merge_config = {
        "input": _input,
        "output": _output,
    }

    # run!
    run_nextflow(
        nextfile_path=nek_base(
            os.path.join("workflow", "main.nf")
        ),  # Full path to Nextflow file
        merge_config=merge_config,
        **kwargs
    )


@click.command()
@click.option(
    "--configfile",
    default="nextflow.config",
    help="Copy template config to file",
    show_default=True,
)
@click.option(
    "--paramsfile", default="params.yaml", help="Custom params file", show_default=True
)
def config(configfile, paramsfile, **kwargs):
    """Copy the system default config files"""
    copy_config(
        local_config=configfile,
        system_config=nek_base(os.path.join("workflow", "nextflow.config")),
    )
    copy_config(
        local_config=paramsfile,
        system_config=nek_base(os.path.join("workflow", "params.yaml")),
    )


@click.command()
def citation(**kwargs):
    """Print the citation(s) for this tool"""
    print_citation()


cli.add_command(run)
cli.add_command(config)
cli.add_command(citation)


def main():
    cli()


if __name__ == "__main__":
    main()
