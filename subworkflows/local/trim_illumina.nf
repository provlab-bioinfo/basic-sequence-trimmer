include {BBMAP_BBDUK as TRIM_BBDUK} from      '../../modules/nf-core/bbmap/bbduk/main'

workflow TRIM_ILLUMINA {   
    take:
        reads

    main:
        versions = Channel.empty()

        TRIM_BBDUK(reads,[])

        versions = versions.mix(TRIM_BBDUK.out.versions.first())

    emit:
        reads = TRIM_BBDUK.out.reads
        versions
}