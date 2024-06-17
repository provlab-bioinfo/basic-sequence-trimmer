include {PORECHOP_PORECHOP as TRIM_PORECHOP}  from '../../modules/nf-core/porechop/porechop/main.nf'  
include {CHOPPER as TRIM_CHOPPER}             from '../../modules/local/chopper/main.nf'  

workflow TRIM_NANOPORE {   
    take:
        reads

    main:
        versions = Channel.empty()

        if (!params.skip_qc) {
            TRIM_PORECHOP(reads)
            versions = versions.mix(TRIM_PORECHOP.out.versions.first())

            TRIM_CHOPPER(TRIM_PORECHOP.out.reads)
            versions = versions.mix(TRIM_CHOPPER.out.versions.first())

            reads = TRIM_CHOPPER.out.fastq
        }    

    emit:
        reads
        versions
}
