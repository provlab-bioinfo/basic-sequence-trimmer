include {HOSTILE as DEHOST_HOSTILE} from '../../modules/local/hostile/main.nf'

workflow DEHOST {   
    take:
        reads
        
    main:
        versions = Channel.empty()
        
        DEHOST_HOSTILE(reads)
        versions = versions.mix(DEHOST_HOSTILE.out.versions.first())

    emit:
        reads = DEHOST_HOSTILE.out.fastq
        versions
}