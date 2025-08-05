// Module files for DelMoro pipeline

// COLLECTING ALIGNMENT SUMMARY METRICS WITH GATK

process AlignmentMetrics {
    tag "COLLECTING ALIGNMENT SUMMARY METRICS WITH GATK"
    publishDir "${params.outdir}/Mapping/BamMetrics/AlignmentMetrics/", mode: "copy"
    cpus "${params.cpus}"

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(bam)
    path ref

    output:
    tuple val(patient_id), path("*.alignment_metrics.txt")

    script:
    """
    gatk CollectAlignmentSummaryMetrics \\
        --INPUT ${bam} \\
        --OUTPUT ${bam.baseName}.alignment_metrics.txt \\
        --REFERENCE_SEQUENCE ${ref}
    """
}

// COLLECTING INSERT SIZE METRICS WITH GATK

process InsertMetrics {
    tag "COLLECTING INSERT SIZE METRICS WITH GATK"
    publishDir "${params.outdir}/Mapping/BamMetrics/InsertMetrics/", mode: "copy"
    cpus "${params.cpus}"

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(bam)

    output:
    tuple val(patient_id), path("*.insert_size_metrics.txt")
    tuple val(patient_id), path("*.insert_size_histogram.pdf")

    script:
    """
    gatk CollectInsertSizeMetrics \\
        --INPUT ${bam} \\
        --OUTPUT ${bam.baseName}.insert_size_metrics.txt \\
        --Histogram_FILE ${bam.baseName}.insert_size_histogram.pdf 
    """
}

// COLLECTING GC BIAS METRICS WITH GATK

process GcBiasMetrics {
    tag "COLLECTING GC BIAS METRICS WITH GATK"
    publishDir "${params.outdir}/Mapping/BamMetrics/GCMetrics/", mode: "copy"
    cpus "${params.cpus}"

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(bam)
    path ref

    output:
    tuple val(patient_id), path("*.gc_bias_metrics.txt")
    tuple val(patient_id), path("*.gc_bias_summary.txt")
    tuple val(patient_id), path("*.gc_bias_plot.pdf")

    script:
    """
    gatk CollectGcBiasMetrics \\
    	--INPUT ${bam} \\
        --OUTPUT ${bam.baseName}.gc_bias_metrics.txt \\
        --CHART_OUTPUT ${bam.baseName}.gc_bias_plot.pdf \\
        --SUMMARY_OUTPUT ${bam.baseName}.gc_bias_summary.txt \\
        --REFERENCE_SEQUENCE ${ref}
    """
}

// RUNNING QUALIMAP BAMQC FOR QC REPORT

process Qualimap {
    tag "RUNNING QUALIMAP BAMQC FOR QC REPORT"
    publishDir "${params.outdir}/Mapping/BamMetrics/Qualimap/", mode: "copy"
    cpus "${params.cpus}"

    conda "bioconda::qualimap==2.3"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://pegi3s/qualimap:latest"
        : "pegi3s/qualimap:latest"}"

    input:
    tuple val(patient_id), path(bam)

    output:
    tuple val(patient_id), path("${bam.baseName}_qualimap_report")

    script:
    """
    mkdir ${bam.baseName}_qualimap_report
    qualimap bamqc \\
        -bam ${bam} \\
        -outdir ${bam.baseName}_qualimap_report \\
        -outformat PDF:HTML
    """
}
