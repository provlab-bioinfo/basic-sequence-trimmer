include {BBMAP_BBDUK} from      '../../modules/nf-core/bbmap/bbduk/main'

workflow ILLUMINA_QC {   
    take:
        reads
    main:
        ch_versions = Channel.empty()
        BBMAP_BBDUK(reads, [])
        ch_versions = ch_versions.mix(BBMAP_BBDUK.out.versions.first())
    emit:
        reads = BBMAP_BBDUK.out.reads
        versions
}