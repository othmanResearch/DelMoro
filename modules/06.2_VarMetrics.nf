// Module files for DelMoro pipeline

// COLLECTING Variant METRICS 

// GENERATE BCFTOOLS STATS FROM VCF 
    
process GenerateStats {
    tag "GENERATE BCFTOOLS STATS FROM VCF"
    publishDir { params.caller ? "${params.outdir}/Variants/deepvariant/Metrics/" : "${params.outdir}/Variants/gatk/Metrics/" }, mode: 'copy'

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
	? "docker://staphb/bcftools:latest"
	: "staphb/bcftools:latest"}"
	
    input:
    tuple val(patient_id), path(vcf), path(gzidx)

    output:
    tuple val(patient_id), path("*_stats.txt")	, emit: statsCh

    script:
    """
    bcftools stats --threads ${task.cpus} ${vcf} > ${vcf.getSimpleName()}_stats.txt
    """
}
