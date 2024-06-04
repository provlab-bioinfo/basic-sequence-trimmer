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
        samplesheet
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
        def getOutPath = {path -> (path == "NA" || path == null) ? '"NA"' : '"' + (new java.io.File(params.outdir + "/" + params.label + "/fastq", new java.io.File(path.toString()).getName().split(/\./)[0] + ".fastq.gz" ).getCanonicalPath()) + '"'} 
        reads = reads.flatMap().map { meta, illumina, nanopore -> ['"' + meta.id + '"', meta.single_end ? getOutPath(illumina) : getOutPath(illumina[0]), meta.single_end ? "NA" : getOutPath(illumina[1]), getOutPath(nanopore)] }
        SAVE_TO_CSV(reads.toList())
        SAVE_TO_CSV.out.samplesheet.view{ "SAVE_SHEET: ${it}"}

    emit:
        samplesheet = SAVE_TO_CSV.out.samplesheet
}

process SAVE_TO_CSV {
    tag "samplesheet.${params.label}.csv"
    label 'process_medium'

    // conda "conda-forge::python=3.9.5"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/python:3.9--1' :
    //     'biocontainers/python:3.9--1' }"

    input:
        val (reads)

    output:
        path "*.csv"       , emit: samplesheet

    when:
        task.ext.when == null || task.ext.when

    script:
         """
        #!/usr/bin/env python
        import sys, csv

        with open('samplesheet.${params.label}.csv', 'w') as f:
            csv_writer = csv.writer(f)
            csv_writer.writerow(["id","illumina1","illumina2","nanopore"])
            csv_writer.writerows(${reads})

        with open('samplesheet.${params.label}.out.csv', 'w') as f:
            csv_writer = csv.writer(f)
            csv_writer.writerow(["id","illumina1","illumina2","nanopore"])
            csv_writer.writerows(${reads})
        """
}

// process UPDATE_PATH {
//     tag "samplesheet.${params.label}.csv"
//     label 'process_medium'

//     conda "conda-forge::python=3.9.5"
//     container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//         'https://depot.galaxyproject.org/singularity/python:3.9--1' :
//         'biocontainers/python:3.9--1' }"

//     input:
//         tuple val(id), val(illumina1), val(illumina2), val(nanopore)

//     output:
//         path "*.csv"       , emit: csv
//         path "versions.yml", emit: versions

//     when:
//         task.ext.when == null || task.ext.when

//     script:
//         """
//         touch samplesheet.${params.label}.csv
//         echo "ID,illumina1,illumina2,nanopore" >> samplesheet.${params.label}.csv
//         echo "${id},${illumina1},${illumina2},${nanopore}" >> samplesheet.${params.label}.csv

//         cat <<-END_VERSIONS > versions.yml
//         "${task.process}":
//             python: \$(python --version | sed 's/Python //g')
//         END_VERSIONS
//         """
// }


// process COPY_SHEET {
//     tag "$samplesheet"
//     label 'process_medium'

//     conda "conda-forge::python=3.9.5"
//     container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//         'https://depot.galaxyproject.org/singularity/python:3.9--1' :
//         'biocontainers/python:3.9--1' }"

//     input:
//         path samplesheet // file: /path/to/samplesheet.csv

//     output:
//         path '*.csv'       , emit: csv
//         path "versions.yml", emit: versions

//     when:
//         task.ext.when == null || task.ext.when  

//     script:
//     """
//     cp $samplesheet \\
//         samplesheet.old.csv
    
//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         python: \$(python --version | sed 's/Python //g')
//     END_VERSIONS
//     """
// } 