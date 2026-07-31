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
    tuple val(patient_id), path(BamFile), path(bamidx)
    path bedtarget    
    
    output:
    tuple val(patient_id), path("*_coverage.bed")

    script:
    def prefix = BamFile.baseName.takeWhile { it != '_' }
    def outfile = (bedtarget.name == "NO_FILE") ? "${prefix}_coverage.bed" : "${prefix}_${bedtarget.baseName}_coverage.bed"
    def target_option = (bedtarget.name == "NO_FILE") ? "" : "-r ${bedtarget}"
    
    """
    echo -e "Chromosome\tStart\tEnd\tCoverage" > ${outfile}
    bamtocov ${target_option} ${BamFile} >> ${outfile}
    """
}

