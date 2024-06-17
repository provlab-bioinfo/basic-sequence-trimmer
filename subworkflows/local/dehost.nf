include {HOSTILE as DEHOST_HOSTILE} from '../../modules/local/hostile/main.nf'

workflow DEHOST {   
    take:
        reads
        
    main:
        versions = Channel.empty()
        
        if (!params.skip_dehost) {
            DEHOST_HOSTILE(reads)
            DEHOST_HOSTILE.out.fastq.set { reads }
            versions = versions.mix(DEHOST_HOSTILE.out.versions.first())
        }       

    emit:
        reads
        versions
}