#!/usr/bin/env nextflow

 /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*\
|   basic-sequence-trimmer                                               |
|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
|   Github : https://github.com/provlab-bioinfo/basic-sequence-trimmer   |
 \*---------------------------------------------------------------------*/

nextflow.enable.dsl = 2
WorkflowMain.initialise(workflow, params, log)

// if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
// if (params.platform != 'illumina' || params.platform == 'nanopore') {exit 1, "Platform must be either 'illumina' or 'nanopore'!" }
// if ((params.sheet == null && params.folder) == null || (params.sheet != null && params.folder != null)) {
//     exit 1, "Must specify one of '--folder' or '--sheet'!"}

include { LOAD_SHEET }                  from './subworkflows/local/load_sheet'
include { SAVE_SHEET }                  from './subworkflows/local/load_sheet'
include { TRIM_ILLUMINA }               from './subworkflows/local/trim_illumina'
include { TRIM_NANOPORE }               from './subworkflows/local/trim_nanopore'
include { DEHOST as DEHOST_ILLUMINA }   from './subworkflows/local/dehost'
include { DEHOST as DEHOST_NANOPORE }   from './subworkflows/local/dehost'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow {
    
    versions = Channel.empty()

    // SUBWORKFLOW: Read in samplesheet
    LOAD_SHEET(file(params.sheet))
    //ids = LOAD_SHEET.out.meta.map { meta -> [ meta , "NA" ] }
    //ids.view{ it -> "IDs: " + it}

    // SUBWORKFLOW: Perform QC
    TRIM_ILLUMINA(LOAD_SHEET.out.illumina)
    TRIM_NANOPORE(LOAD_SHEET.out.nanopore)

    versions = versions.mix(TRIM_ILLUMINA.out.versions)
    versions = versions.mix(TRIM_NANOPORE.out.versions)

    //SUBWORKFLOW: Dehosting
    // TRIM_ILLUMINA.out.reads.view()

    DEHOST_ILLUMINA(TRIM_ILLUMINA.out.reads)
    illumina_reads = DEHOST_ILLUMINA.out.reads
    versions = versions.mix(DEHOST_ILLUMINA.out.versions)

    DEHOST_NANOPORE(TRIM_NANOPORE.out.reads)
    nanopore_reads = DEHOST_NANOPORE.out.reads
    versions = versions.mix(DEHOST_NANOPORE.out.versions)

    // illumina_reads = illumina_reads.join(ids, remainder: true).map { meta, illumina, blank -> [ meta , illumina ] }
    // nanopore_reads = nanopore_reads.join(ids, remainder: true).map { meta, nanopore, blank -> [ meta , nanopore ] }

    //illumina_reads.view{ it -> "Illumina: " + it}
    //nanopore_reads.view{ it -> "Nanopore: " + it}
    reads = illumina_reads.join(nanopore_reads, remainder: true)
    reads.view{ it -> "Reads before: " + it}                   

    reads = reads.map { meta, illumina, nanopore -> [ meta , illumina ? illumina : ["NA","NA"], nanopore ? nanopore : "NA" ] }
    reads.view{ it -> "Reads after: " + it}

    SAVE_SHEET(reads)
    samplesheet = SAVE_SHEET.out.samplesheet
    //samplesheet = Channel.empty()

    // SUBWORKFLOW: Get versioning
    CUSTOM_DUMPSOFTWAREVERSIONS (versions.unique().collectFile(name: 'collated_versions.yml'))    

    emit:
        // reads = [ LOAD_SHEET.out.meta, TRIM_ILLUMINA.out.reads, TRIM_NANOPORE.out.reads ]
        reads //= [ LOAD_SHEET.out.meta, illumina_reads, nanopore_reads ]
        samplesheet
        versions
}