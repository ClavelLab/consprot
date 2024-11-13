nextflow.enable.dsl=2

include { PYRODIGAL } from './modules/nf-core/pyrodigal/main'
include { DIAMOND_MAKEDB } from './modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP } from './modules/nf-core/diamond/blastp/main'

workflow {
    // List genomes files according to extension and
    //  format a meta map to use nf-core modules
    ch_genomes = Channel.fromPath(
        params.input + "/*." + params.extension,
        checkIfExists:true
    ).map{
        tuple(['id': it.baseName], it)
    }

    // Predict proteins from genomes
    // [ [meta], [.faa.gz] ]
    ch_proteins = PYRODIGAL(ch_genomes)
    // Create diamond database
    ch_diamond_db = DIAMOND_MAKEDB( ch_proteins )
    ch_diamond_db.db.view()
}
