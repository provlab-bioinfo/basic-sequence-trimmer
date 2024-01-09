process HOSTILE {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::hostile=0.4.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hostile:0.4.0--pyhdfd78af_0':
        'biocontainers/hostile:0.4.0--pyhdfd78af_0' }"

    input: 
        tuple val(meta), path(fastq)

    output:
        tuple val(meta), path("*.fastq.gz") , emit: fastq
        path "versions.yml"  , emit: versions

    script:
    """
    if [ ${fastq[1]} == null ]
    then
        hostile clean --fastq1 ${fastq[0]} --aligner minimap2 --index ${params.hostile_index_long}
    else
        hostile clean --fastq1 ${fastq[0]} --fastq2 ${fastq[1]} --aligner bowtie2 --index ${params.hostile_index_short}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hostile: \$(hostile --version 2>&1 | cut -d ' ' -f 2)
    END_VERSIONS
    """
}