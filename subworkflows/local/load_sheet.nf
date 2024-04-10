//
// Check input samplesheet and get read channels
//

// include { mergeCsv } from 'plugin/nf-boost'

workflow LOAD_SHEET {
    take:
        samplesheet // file: /path/to/samplesheet.csv

    main:
        Channel.fromPath(samplesheet).splitCsv ( header:true, sep:',' )        
            .map { create_read_channels(it) }
            .set { reads }

        reads.map { meta, illuminaFQ, nanopore -> meta }
            .set { meta }

        reads.map { meta, illuminaFQ, nanopore -> [ meta, illuminaFQ ] }
            .filter { meta, illuminaFQ -> illuminaFQ[0] != 'NA' && illuminaFQ[1] != 'NA' }
            .set { illumina }
        
        reads.map {meta, illuminaFQ, nanopore -> [ meta, nanopore ] }
            .filter { meta, nanopore -> nanopore != 'NA' }
            .set { nanopore }

    emit:
        reads      // channel: [ val(meta), ( [ illumina ] | nanopore ) ]
        meta
        illumina
        nanopore
        //samplesheet
}

// Function to get list of [ meta, [ illumina1, illumina2 ], nanopore ]
def create_read_channels(LinkedHashMap row) {
    
    def meta = [:]
    meta.id           = row.id
    meta.single_end   = !(row.illumina1 == 'NA') && !(row.illumina2 == 'NA') ? false : true

    illumina1 = checkRead(row.illumina1)
    illumina2 = checkRead(row.illumina2)
    nanopore  = checkRead(row.nanopore)
    
    def array = []
    if ( meta.single_end ) {
        illumina = row.illumina1 == 'NA' ? illumina2 : illumina1
        array = [ meta, [ illumina ], nanopore]
    } else {
        array = [ meta, [ illumina1, illumina2 ], nanopore ]
    } 
    return array 
}

def checkRead(String read) {
    if (read == 'NA' | read == "") return 'NA'
    if (!file(read).exists())    exit 1, "ERROR: Please check input samplesheet -> FASTQ file does not exist!\n   ${read}"        
    if (file(read).size() == 0)  exit 1, "ERROR: Please check input samplesheet -> FASTQ file is empty!\n   ${read}"
    return file(read)
}

workflow SAVE_SHEET {
    take:
        reads // channel: [ val(meta), ( [ illumina ] | nanopore ) ]

    main:
        //reads.view{ "SAVE_SHEET reads: $it" }
        def getOutPath = {path -> (path == "NA" || path == null) ? "NA" : new java.io.File(params.outdir + "/" + params.label + "/fastq", new java.io.File(path.toString()).getName()).getCanonicalPath()} 
        reads
          | flatMap
          | map { meta, illumina, nanopore -> ["id": meta.id, "illumina1": getOutPath(illumina[0]), "illumina2": getOutPath(illumina[1]), "nanopore": getOutPath(nanopore)] }
          | collect
          | SAVE_TO_CSV 
          | set {samplesheet}
        // SAVE_TO_CSV(reads.collect()).set { samplesheet }
        //reads.view{ "SAVE_SHEET reads2: $it" }
        //SAVE_TO_CSV(reads).csv.collectFile(name: 'samplesheet.csv', keepHeader: true).map { it }.set { samplesheet }
        //SAVE_TO_CSV.out.versions.view{ "Versions: $it" }
        //SAVE_TO_CSV.out.csv.view{ "Samplesheets: $it" }
        //samplesheet = Channel.empty()

    emit:
        samplesheet
}

process SAVE_TO_CSV {

  input:
    val reads

  output:
    path 'samplesheet.csv', emit: samplesheet

  exec:
    mergeCsv(reads, task.workDir.resolve('samplesheet.csv'), sep: '\t')
}

// process SAVE_TO_CSV {
//     tag "$id"
//     label 'process_medium'

//     conda "conda-forge::python=3.9.5"
//     container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//         'https://depot.galaxyproject.org/singularity/python:3.9--1' :
//         'biocontainers/python:3.9--1' }"

//     input:
//         tuple val(id), val(illumina1), val(illumina2), val(nanopore)

//     output:
//         path '*.csv'       , emit: csv
//         path "versions.yml", emit: versions

//     when:
//         task.ext.when == null || task.ext.when

//     script: // This script is bundled with the pipeline, in nf-core/rnaseq/bin/
//         """
//         touch ${id}_samplesheet.csv
//         echo "ID,illumina1,illumina2,nanopore" >> ${id}_samplesheet.csv
//         echo "${id},${illumina1},${illumina2},${nanopore}" >> ${id}_samplesheet.csv

//         cat <<-END_VERSIONS > versions.yml
//         "${task.process}":
//             python: \$(python --version | sed 's/Python //g')
//         END_VERSIONS
//         """
// }

def create_write_channels(LinkedHashMap row) {



}

// include { mergeCsv } from 'plugin/nf-boost'

// process RECORDS_TO_CSV {
//   publishDir 'results'

//   input:
//   val records

//   output:
//   path 'records.txt'

//   exec:
//   def path = task.workDir.resolve('records.txt')
//   mergeCsv(records, path, sep: '\t')
// }


// workflow {
//   Channel.of( 1..10 )
//     | map { i -> ['id': i, 'name': "record_${i}"] }
//     | collect
//     | RECORDS_TO_CSV
//     | view { csv -> csv.text }
// }