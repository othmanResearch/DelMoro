// Module files for DelMoro pipeline

process DownloadKns1 {
    tag "Downloading ${params.ivcf1}"
    publishDir "./knownsites/${params.ivcf1}/", mode: 'copy'
    storeDir "./knownsites/${params.ivcf1}/"
    errorStrategy 'retry'
    maxRetries 3

    conda "conda-forge::awscli=2.23.6"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://xueshanf/awscli:alpine-3.16"
        : "xueshanf/awscli:alpine-3.16"}"

    output:
    path "*", emit: igenome_ch

    script:
    def filename = "${params.IVCF[params.ivcf1].vcf.tokenize('/').last()}"

    """
    aws s3 cp --no-sign-request \\
	--region eu-west-1 ${params.IVCF[params.ivcf1].vcf} ./
    """
}

process DownloadKns2 {
    tag "Downloading ${params.ivcf2}"
    publishDir "./knownsites/${params.ivcf2}/", mode: 'copy'
    storeDir "./knownsites/${params.ivcf2}/"
    errorStrategy 'retry'
    maxRetries 3

    conda "conda-forge::awscli=2.23.6"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://xueshanf/awscli:alpine-3.16"
        : "xueshanf/awscli:alpine-3.16"}"

    output:
    path "*", emit: igenome_ch

    script:
    def filename = "${params.IVCF[params.ivcf2].vcf.tokenize('/').last()}"

    """ 
    aws s3 cp --no-sign-request \\
    --region eu-west-1 ${params.IVCF[params.ivcf2].vcf} ./
    """
}

// indexing known sites files 

process IndexVcf {
    tag "CREATING INDEX FOR VCF FILES"
    publishDir "./knownsites/", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(fileName), path (vcfFile)

    output:
    tuple val(fileName), path ("${vcfFile}.{tbi,idx}")

    script:
    """
    gatk IndexFeatureFile \\
	--input ${vcfFile} 
    """
}

// BaseRecalibration 

process BaseRecalibrator {
    tag "CREATING TABLE FOR BQSR"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    //path sor_md_bam_file
    tuple val(patient_id), path(sor_md_bam_file), path(bamidx)
    tuple val(fileName), path (knownsiteFile1), path (IDXknsF1)  // knsite1 + index 
    tuple val(fileName), path (knownsiteFile2), path (IDXknsF2)  // knsite2 + index

    output:
    tuple val(patient_id), path("*bqsr.table"), emit: "BQSR_Table"
    //path "*bqsr.table", emit: "BQSR_Table"

    script:
    """
    gatk BaseRecalibrator \\
	--reference ${ref} \\
	--input ${sor_md_bam_file} \\
	--known-sites ${knownsiteFile1} \\
	--known-sites ${knownsiteFile2} \\
	--output ${sor_md_bam_file.baseName}.bqsr.table
    """
}

// Apply base Recalibration 

process ApplyBQSR {
    tag "APPLYING BASE QUALITY SCORE RECALIBRATION"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    //path sor_md_bam_file
    tuple val(patient_id), path(sor_md_bam_file), path(bamidx), path (bqsrTABLE)

    output:
    tuple val(patient_id), path("*.recal.bam"), emit: "recal_bam"

    script:
    """
    gatk ApplyBQSR \\
	--input ${sor_md_bam_file} \\
	--bqsr-recal-file ${bqsrTABLE} \\
	--output ${sor_md_bam_file.baseName}.recal.bam
    """
}

// Generating Indexes of Recalibrated Bam files

process IndexRecalBam {
    tag "CREATING INDEX FOR Recalibrated BAM FILES"
    publishDir "${params.outdir}/Mapping/", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwa-samtools:latest"
        : "firaszemzem/bwa-samtools:latest"}"

    input:
    tuple val(patient_id), path(RecalBamFile)

    output:
    tuple val(patient_id), path("${RecalBamFile}.bai"), emit: "IDXRECALBAM"

    script:
    """
    samtools index -@ ${task.cpus}  ${RecalBamFile}
    """
}
