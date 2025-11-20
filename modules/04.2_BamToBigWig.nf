// Module files for DelMoro pipeline

// GENRATE BIGWIG FILE FROM BAM FILES


process BigWig {
    tag " GENRATE BIGWIG FILES "
    publishDir "${params.outdir}/Mapping/", mode: "copy"
    errorStrategy 'retry'
    maxRetries 3

    
    conda "bioconda::deeptools==3.5.5"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://mgibio/deeptools:3.5.3"
        : "mgibio/deeptools:3.5.3"}"
      
    input: 
    tuple val(patient_id), path(bam)
    tuple val(patient_id), path(bamIdx)
 	
    output: 
    tuple val(patient_id), path("*.bw")
    	
    script:
     
    """
    bamCoverage --bam $bam \\
    --numberOfProcessors ${task.cpus} \\
    --outFileName ${bam.baseName}.bw
    """
}



