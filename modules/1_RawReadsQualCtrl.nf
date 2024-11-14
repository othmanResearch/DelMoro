// Module files for DelMoro pipeline

// Check Raw reads Quality ;

process FastqQc {
        conda 'bioconda::fastqc=0.12.1'
        tag "GENERATING QUALITY FOR RAW READS"
        publishDir "${params.outdir}/QualityControl/RAW/", mode: 'copy'
	container "biocontainers/fastqc"
        input:
        	tuple val(patient_id), path(R1), path(R2)

        output:
        	path "*.{html,zip}"

        script:
        """
        fastqc -t {params.cpus} ${R1} ${R2} 
        """
}



// Gathering Qc Reports ;

process ReadsMultiqc {
	conda 'bioconda::multiqc=1.25.1'

    	tag "Gathering Multiqc FOR RAW READS"
        publishDir "${params.outdir}/QualityControl/RAW/multiqc/" ,  mode:'copy'
        
        input:
            path (fastqc)  
            
        output:
            path "{multiqc_data,multiqc_report.html}" 
           
        script:
        """
        multiqc .
        """
}

