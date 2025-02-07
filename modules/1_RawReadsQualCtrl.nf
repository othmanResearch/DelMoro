// Module files for DelMoro pipeline

// Check Raw reads Quality ;

process FastqQc {
    tag "GENERATING QUALITY FOR RAW READS"
    publishDir "${params.outdir}/QualityControl/RAW/", mode: 'copy'
    errorStrategy 'ignore'

    conda "bioconda::fastqc=0.12.1"
    container "${ workflow.containerEngine == 'singularity' ?
		"docker://staphb/fastqc:0.12.1" :
		"staphb/fastqc:0.12.1" 		}"

    input:
	tuple val(patient_id), path(R1), path(R2)
	
    output:
        path "*.{html,zip}"

    script:
    """
    fastqc -t ${task.cpus} ${R1} ${R2}
    """
}

// Gathering Qc Reports ;

process ReadsMultiqc {
    tag "Gathering Multiqc FOR RAW READS"
    publishDir "${params.outdir}/QualityControl/RAW/multiqc/" ,  mode:'copy'

    
    conda "bioconda::multiqc=1.27"
    container "${ workflow.containerEngine == 'singularity' ? 
		"docker://multiqc/multiqc:latest" : 
                "multiqc/multiqc:latest"    	  }"

    input:
        path (fastqc)
            
    output:
        path "{multiqc_data,multiqc_report.html}"
           
    script:
    """
    multiqc . --ai
    """
}

