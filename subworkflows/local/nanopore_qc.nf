include {PORECHOP_PORECHOP}  from '../../modules/nf-core/porechop/porechop/main.nf'  
include {CHOPPER}  from '../../modules/local/chopper/main.nf'  

workflow QC {   
    take:
        reads
    main:
        ch_versions = Channel.empty()
        PORECHOP_PORECHOP(reads)
        ch_versions = ch_versions.mix(PORECHOP_PORECHOP.out.versions.first())
        CHOPPER(PORECHOP_PORECHOP.out.reads)
        ch_versions = ch_versions.mix(CHOPPER.out.versions.first())
    emit:
        reads = CHOPPER.out.fastq
        versions
}