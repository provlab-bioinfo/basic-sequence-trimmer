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
include { TRIM_ILLUMINA }               from './subworkflows/local/trim_illumina'
include { TRIM_NANOPORE }               from './subworkflows/local/trim_nanopore'
include { DEHOST as DEHOST_ILLUMINA }   from './subworkflows/local/dehost'
include { DEHOST as DEHOST_NANOPORE }   from './subworkflows/local/dehost'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow {
    
    versions = Channel.empty()

    // SUBWORKFLOW: Read in samplesheet
    LOAD_SHEET(file(params.sheet))

    // SUBWORKFLOW: Perform QC
    TRIM_ILLUMINA(LOAD_SHEET.out.illumina)
    TRIM_NANOPORE(LOAD_SHEET.out.nanopore)

    versions = versions.mix(TRIM_ILLUMINA.out.versions)
    versions = versions.mix(TRIM_NANOPORE.out.versions)

    //SUBWORKFLOW: Dehosting
    // TRIM_ILLUMINA.out.reads.view()

    DEHOST_ILLUMINA(TRIM_ILLUMINA.out.reads)
    illumina_reads = DEHOST_ILLUMINA.out.reads

    DEHOST_NANOPORE(TRIM_NANOPORE.out.reads)
    nanopore_reads = DEHOST_NANOPORE.out.reads

    versions = versions.mix(DEHOST_ILLUMINA.out.versions)

    // SUBWORKFLOW: Get versioning
    CUSTOM_DUMPSOFTWAREVERSIONS (versions.unique().collectFile(name: 'collated_versions.yml'))    

    emit:
        // reads = [ LOAD_SHEET.out.meta, TRIM_ILLUMINA.out.reads, TRIM_NANOPORE.out.reads ]
        reads = [ LOAD_SHEET.out.meta, illumina_reads, nanopore_reads ]
        versions
}