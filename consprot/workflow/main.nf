nextflow.enable.dsl=2

include { PYRODIGAL } from './modules/nf-core/pyrodigal/main'

process any2fasta {
  //conda environemnt
  conda 'bioconda::any2fasta=0.4.2'
  
  //singularity image
  container 'https://depot.galaxyproject.org/singularity/any2fasta:0.4.2--hdfd78af_3' 
  
  ////docker image
  //container 'quay.io/biocontainers/any2fasta:0.4.2--hdfd78af_3'                       

  input: path(FQ)

  output: stdout

  script:
  """
  which any2fasta
  any2fasta $FQ 
  """
}


workflow {
    // List genomes files according to extension and
    //  format a meta map to use nf-core modules
    ch_genomes = Channel.fromPath(
        params.input + "/*." + params.extension,
        checkIfExists:true
    ).map{
        tuple(['id': it.baseName], it)
    }
    ch_genomes.view()

    ch_proteins = PYRODIGAL(ch_genomes)

    ch_proteins.faa.view()

}
