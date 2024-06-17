#!/usr/bin/env nextflow

 /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*\
|   basic-sequence-trimmer                                               |
|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
|   Github : https://github.com/provlab-bioinfo/basic-sequence-trimmer   |
 \*---------------------------------------------------------------------*/

nextflow.enable.dsl = 2
WorkflowMain.initialise(workflow, params, log)

include { LOAD_SHEET }                  from './subworkflows/local/sheet_ops'
include { SAVE_DATA }                   from './subworkflows/local/sheet_ops'
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

    // SUBWORKFLOW: Dehosting
    DEHOST_ILLUMINA(TRIM_ILLUMINA.out.reads)
    illumina_reads = DEHOST_ILLUMINA.out.reads
    versions = versions.mix(DEHOST_ILLUMINA.out.versions)

    DEHOST_NANOPORE(TRIM_NANOPORE.out.reads)
    nanopore_reads = DEHOST_NANOPORE.out.reads
    versions = versions.mix(DEHOST_NANOPORE.out.versions)

    // SUBWORKFLOW: Create new samplesheet
    reads = illumina_reads.join(nanopore_reads, remainder: true)
    SAVE_DATA(reads.toList())

    // SUBWORKFLOW: Get versioning
    CUSTOM_DUMPSOFTWAREVERSIONS (versions.unique().collectFile(name: 'collated_versions.yml'))    

    emit:
        samplesheet = SAVE_DATA.out.samplesheet
        files = SAVE_DATA.out.files
        versions
}