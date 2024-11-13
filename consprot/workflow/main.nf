nextflow.enable.dsl=2


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
    ch_genomes = Channel.fromPath(params.input + "/*." + params.extension, checkIfExists:true)
    ch_genomes.view()
}
