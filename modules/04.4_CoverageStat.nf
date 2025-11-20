// Module files for DelMoro pipeline

// GENERATES A COVERAGE FILE IN BED FORMAT

process BamCoverage {
    tag "GENERATES BAM COVERAGE"
    publishDir "${params.outdir}/Mapping/BamCoverage/", mode: 'copy'

    conda "bioconda::bamtocov=2.7.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"
        : "quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"}"

    input:
    tuple val(patient_id), path(BamFile)
    tuple val(patient_id), path(bamidx)

    output:
    tuple val(patient_id), path("*_coverage.bed")

    script:
    """
    echo -e "Chromosome\tStart\tEnd\tCoverage" > ${BamFile.baseName.takeWhile { it != '_' }}_coverage.bed
    bamtocov ${BamFile} >> ${BamFile.baseName.takeWhile { it != '_' }}_coverage.bed
    """
}

// GENERATES A COVERAGE FROM TARGETED FILE 

process BamTargetCoverage {
    tag "GENERATES BAM COVERAGE PER TARGET IN BAM"
    publishDir "${params.outdir}/Mapping/BamCoverage/", mode: 'copy'

    conda "bioconda::bamtocov=2.7.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"
        : "quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"}"

    input:
    tuple val(patient_id), path(BamFile)
    tuple val(patient_id), path(bamidx)
    path target

    output:
    tuple val(patient_id), path("*_targeted_coverage.bed")

    script:
    """
    bamtocounts --header --coords \\
    ${target} ${BamFile} >> ${BamFile.baseName.takeWhile { it != '_' }}_targeted_coverage.bed
    """
}
