include {BBMAP_BBDUK as TRIM_BBDUK} from      '../../modules/nf-core/bbmap/bbduk/main'

workflow TRIM_ILLUMINA {   
    take:
        reads

    main:
        versions = Channel.empty()

        if (!params.skip_qc) {
            TRIM_BBDUK(reads,[])
            TRIM_BBDUK.out.reads.set { reads }
            versions = versions.mix(TRIM_BBDUK.out.versions.first())
        }

    emit:
        reads
        versions
}