nextflow.enable.dsl=2

include { PYRODIGAL } from './modules/nf-core/pyrodigal/main'
include { DIAMOND_MAKEDB } from './modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP } from './modules/nf-core/diamond/blastp/main'
include { DIAMOND_DBINFO } from './modules/local/diamond/dbinfo/main'
include { COUNT_PROTEINS } from './modules/local/count_proteins/main'
include { FILTER_MATCHES } from './modules/local/filter_matches/main'
include { COMPUTE_POCPU } from './modules/local/compute_pocpu/main'

workflow {
    // List genomes files according to extension and
    //  format a meta map to use nf-core modules
    ch_genomes = Channel.fromPath([
        params.input + "/*.fa",
        params.input + "/*.fna",
        params.input + "/*.fasta"
    ],
        checkIfExists:false
    ).map{
        tuple(['id': it.baseName],
            file(it, checkIfExists:true)
        )
    }

    // Predict proteins from genomes
    // [ [meta], [.faa.gz] ]
    ch_proteins = PYRODIGAL(ch_genomes)
    // Create diamond database
    ch_diamond_db = DIAMOND_MAKEDB( ch_proteins )

    // Get total number of proteins per genome
    //  via the diamond database info
    ch_db_info = DIAMOND_DBINFO( ch_diamond_db )
    ch_counts = COUNT_PROTEINS( ch_db_info.out)

    protein_counts_csv = ch_counts.csv.collectFile(
        name: 'proteins_counts.csv', skip: 1, keepHeader: true,  storeDir: workDir
    ) { it[1] } // extract the second element as the first is the propagated meta



    // Prepare the channel for the pairwise comparisons
    // e.g. with quinoa and strawberry
    input_diamond=ch_proteins.combine(ch_diamond_db)
    /*
        [[id:quinoa], data/quinoa.faa, [id:quinoa], data/quinoa.dmnd]
        [[id:strawberry], data/strawberry.faa, [id:quinoa], data/quinoa.dmnd]
        [[id:quinoa], data/quinoa.faa, [id:strawberry], data/strawberry.dmnd]
        [[id:strawberry], data/strawberry.faa, [id:strawberry], data/strawberry.dmnd]
    */
    .filter{meta_Q, Query, meta_S, Subject -> meta_Q.get('id')!= meta_S.get('id')}
    /*
        [[id:quinoa], data/quinoa.faa, [id:strawberry], data/strawberry.dmnd]
        [[id:strawberry], data/strawberry.faa, [id:quinoa], data/quinoa.dmnd]
    */
    .map{meta_Q,Query,meta_S,Subject ->
        tuple(
            ['id':[meta_Q.get('id'),meta_S.get('id')].join('--')],
            Query,
            meta_S,
            Subject)}
    /*
        [[id:strawberry--quinoa], data/strawberry.faa, [id:quinoa], data/quinoa.dmnd]
        [[id:quinoa--strawberry], data/quinoa.faa, [id:strawberry], data/strawberry.dmnd]
   */
    .multiMap{
        // from a unique channel to 2 named channels
        // needed because diamond's process expects 4 Channels not a 4-tuple
            it ->
                query_faa: tuple(it[0], it[1]) // [id:strawberry--quinoa], data/strawberry.faa
                subject_db: tuple(it[2], it[3]) // [id:quinoa], data/quinoa.dmnd
            }

    // Run the pairwise comparisons and filter the matches
    ch_diamond=DIAMOND_BLASTP(
                input_diamond.query_faa,
                input_diamond.subject_db,
                // normally the last two channels are optional
                //  but nextflow complains if not present
                Channel.value("txt"),
                Channel.value(
                    "qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"
                )
            )
    ch_matches=FILTER_MATCHES( ch_diamond.txt )

    matches_csv = ch_matches.csv.collectFile(
        name: 'filtered_matches.csv', skip: 1, keepHeader: true,  storeDir: workDir
    ) { it[1] } // extract the second element as the first is the propagated meta

    pocpu_csv = COMPUTE_POCPU( protein_counts_csv, matches_csv )
}

workflow.onComplete {

    println ( workflow.success ? """
        ---------------------------
        Genome directory     : ${params.input}
        POCPu results        : ${params.output}/pocpu.csv
        Nerdy nextflow report: ${params.output}/report.html
        """ : """
        Failed: ${workflow.errorReport}
        exit status : ${workflow.exitStatus}
        """
    )
}
