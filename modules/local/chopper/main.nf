process CHOPPER {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::chopper=0.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chopper:0.6.0--hdcf5f25_0':
        'biocontainers/chopper:0.6.0--hdcf5f25_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.fastq.gz") , emit: fastq
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def args2  = task.ext.args2  ?: ''
    def args3  = task.ext.args3  ?: ''
    def prefix = task.ext.prefix
    def out = "${meta.id}_ONT.${prefix}.fastq.gz"

    if ("$fastq" == out) error "Input and output names are the same, set prefix in module configuration to disambiguate!"
    """
    zcat \\
        $args \\
        $fastq | \\
    chopper \\
        --threads $task.cpus \\
        $args2 | \\
    gzip \\
        $args3 > ${out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chopper: \$(chopper --version 2>&1 | cut -d ' ' -f 2)
    END_VERSIONS
    """
}