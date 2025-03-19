// Module files for DelMoro pipeline
 
// Trimming with Trimmomatic 

process Trimmomatic {  
    tag "TRIMMIG READS WITH TRIMMOMATIC"

    publishDir path: "${params.outdir}/TrimmedREADS/", mode: 'copy'

    conda "bioconda::trimmomatic=0.39"
    container "${ workflow.containerEngine == 'singularity' ?
        "docker://quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2" :
        "quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2" }"

    input:
    tuple val(patient_id), path(R1), path(R2), val(MINLEN), val(LEADING), val(TRAILING), val(SLIDINGWINDOW)
 

    output:
    path "*.fastq"		, emit: paired 		// To be used in DOWNSTREAM Analysis
    path "*_unpaired.fastq"	, emit: unpaired

    script:
    def adapterFile = params.adapters ? "ILLUMINACLIP:${params.adapters}:2:30:10" : ""
    
    """ 
        trimmomatic PE \\
        -threads ${task.cpus} \\
        ${R1} ${R2} \\
        ${R1.baseName.takeWhile{ it != '.' }}.fastq \\
        ${R1.baseName.takeWhile{ it != '.' }}_unpaired.fastq \\
        ${R2.baseName.takeWhile{ it != '.' }}.fastq \\
        ${R2.baseName.takeWhile{ it != '.' }}_unpaired.fastq \\
        MINLEN:${MINLEN} \\
        LEADING:${LEADING} \\
        TRAILING:${TRAILING} \\
        SLIDINGWINDOW:${SLIDINGWINDOW} \\
        ${adapterFile}
    """
}

// Trimming with Fastp

process Fastp {
    tag "TRIMMING WITH FASTP"
    
    publishDir path: "${params.outdir}/TrimmedREADS/", mode: 'copy', pattern: "*.fastq"
    publishDir path: "${params.outdir}/QualityControl/fastpMetrics", mode: 'copy', pattern: "*.{html,json}"

    conda "bioconda::fastp=0.23.2"
    container "${ workflow.containerEngine == 'singularity' ?
        "docker://quay.io/biocontainers/fastp:0.23.2--h79da9fb_0" :
        "quay.io/biocontainers/fastp:0.23.2--h79da9fb_0" }"

    input:
    	tuple val(patient_id), path(R1), path(R2)

    output:
	path "*.fastq"		, emit: fastpFastq
	path "*.{html,json}"	, emit: fastpMetrics

    script: 
    def adapterFile = params.adapters ? "--adapter_fasta ${file(params.adapters)}" : ""

    """
    fastp \\
    -i ${R1} \\
    -I ${R2} \\
    -o ${patient_id}_1.fastq \\
    -O ${patient_id}_2.fastq \\
    ${adapterFile} \\
    --html ${patient_id}_fastp_report.html \\
    --json ${patient_id}_fastp_report.json \\
    --thread ${task.cpus}    
    """
}

// Trimming with Bbduk

process Bbduk {
    tag "TRIMMING WITH BBDUK"
    publishDir path: "${params.outdir}/TrimmedREADS/", mode: 'copy'

    conda "bioconda::bbmap=39.18"
    container "${ workflow.containerEngine == 'singularity' ?
        "docker://quay.io/biocontainers/bbmap:39.18--he5f24ec_0" :
        "quay.io/biocontainers/bbmap:39.18--he5f24ec_0" }"
        
    input:
    	tuple val(patient_id), path(R1), path(R2)
    
    output:
    	path "*"	, emit: bbdukFastq

    script:
    def adapterFile = params.adapters ? "ref=${file(params.adapters)}" : ""
    
    """
    bbduk.sh \\
    in1=${R1} \\
    in2=${R2} \\
    out1=${patient_id}_1.fastq \\
    out2=${patient_id}_2.fastq \\
    ${adapterFile} \\
    k=12 \\
    trimq=20 \\
    minlen=50 \\
    threads=${task.cpus} \\
    tbo
    """   
} 

// Check Trimmed reads Quality ;
 
process TrimmedQC {
    tag "CHECK TRIMMED READS QUALITY"
    publishDir "${params.outdir}/QualityControl/TRIMMED/", mode: 'copy'

    conda "bioconda::fastqc=0.12.1"    
    container "${ workflow.containerEngine == 'singularity' ?
		"docker://staphb/fastqc:0.12.1" :
		"staphb/fastqc:0.12.1" 		}"

    input:
	path(reads)

    output:
	path "*.{html,zip}"

    script:
    """
    fastqc -t ${task.cpus} ${reads}
    """
}

// GATHER TRIMMED QC REPORTS 

process MultiqcTrimmed {
    tag "GATHER TRIMMED QC REPORTS"
    publishDir "${params.outdir}/QualityControl/TRIMMED/multiqc/" ,  mode:'copy'

    conda "bioconda::multiqc=1.27"
    container "${ workflow.containerEngine == 'singularity' ?
		"docker://multiqc/multiqc:latest" :
		"multiqc/multiqc:latest" 	  }"


    input:
	path (fastqc)
            
    output:
	path "{multiqc_data,multiqc_report.html}"
           
    script:
    """
    multiqc . --ai
    """
}

