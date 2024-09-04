// Module files for DelMoro pipeline
 
//Trimming by Trimmomatic 

process Trimming {
	conda "bioconda::trimmomatic=0.39 "
    	tag "TRIMMIG READS"
	publishDir path: "${params.outdir}/TrimmedREADS/", mode: 'copy' 
   
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
    	conda "bioconda::fastqc=0.12.1"
    	tag "CHECK TRIMMED READS QUALITY"
        publishDir "${params.outdir}/QualityControl/TRIMMED/", mode: 'copy'

        
        input:
        	path(reads)

        output:
             	path "*.{html,zip}"  

        script:
        """
        fastqc ${reads} 
        """
}

// GATHER TRIMMED QC REPORTS 

process MultiqcTrimmed {
	conda "bioconda::multiqc=1.17"
    	tag "GATHER TRIMMED QC REPORTS"
        publishDir "${params.outdir}/QualityControl/TRIMMED/multiqc/" ,  mode:'copy'

        
        input:
            	path (fastqc)  
            
        output:
            	path "{multiqc_data,multiqc_report.html}" 
           
        script:
        """
        multiqc .
        """
}

