include {HOSTILE as HOSTILE_DEHOST} from '../../modules/local/hostile/main.nf'

workflow DEHOST {   
    take:
        reads
        
    main:
        versions = Channel.empty()
        
        HOSTILE_DEHOST(reads)
        versions = versions.mix(HOSTILE_DEHOST.out.versions.first())

    emit:
        reads = HOSTILE_DEHOST.out.fastq
        versions
}