nextflow.enable.dsl=2

include { PYRODIGAL } from './modules/nf-core/pyrodigal/main'
include { DIAMOND_MAKEDB } from './modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP } from './modules/nf-core/diamond/blastp/main'
include { DIAMOND_DBINFO } from './modules/local/diamond/dbinfo/main'
include { COUNT_PROTEINS } from './modules/local/count_proteins/main'

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

    // Fetch database info
    ch_db_info = DIAMOND_DBINFO( ch_diamond_db )
    ch_counts = COUNT_PROTEINS( ch_db_info.out)
    ch_counts.csv.view()
}
