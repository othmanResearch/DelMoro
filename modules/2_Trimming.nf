// Module files for DelMoro pipeline
 
//Trimming by Trimmomatic 

process Trimming {
    tag "TRIMMIG READS"
    publishDir path: "${params.outdir}/TrimmedREADS/", mode: 'copy'

    conda "bioconda::trimmomatic=0.39 "
    container "${ workflow.containerEngine == 'singularity' ?
		"docker://quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2" 	:
		"quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2" 		}"


    input:
	tuple val(patient_id), path(R1), path(R2), val(MINLEN), val(LEADING), val(TRAILING), val(SLIDINGWINDOW)
    
    output:
    	path "*.fastq"			, emit: paired  	// To be used in DOWNSTREAM Analysis
	path "*_unpaired.fastq"		, emit: unpaired
        	
    script:
    """
    trimmomatic PE \\
	-threads ${params.cpus} \\
	${R1} ${R2} \\
	${R1.baseName.takeWhile{ it != '.' }}.fastq \\
	${R1.baseName.takeWhile{ it != '.' }}_unpaired.fastq \\
	${R2.baseName.takeWhile{ it != '.' }}.fastq \\
	${R2.baseName.takeWhile{ it != '.' }}_unpaired.fastq \\
	MINLEN:${MINLEN} \\
	LEADING:${LEADING} \\
	TRAILING:${TRAILING} \\
	SLIDINGWINDOW:${SLIDINGWINDOW}
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
    fastqc -t ${params.cpus} ${reads}
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

