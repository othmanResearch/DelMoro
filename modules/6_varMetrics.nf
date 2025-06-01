// Module files for DelMoro pipeline

// COLLECTING Variant METRICS 

// GENERATE BCFTOOLS STATS FROM VCF 
    
process GenerateStats {
    tag "GENERATE BCFTOOLS STATS FROM VCF"
    publishDir "${params.outdir}/Variants/Metrics/", mode: 'copy'
    cpus 8

    input:
    path vcf
    path gzidx

    output:
    path "*_stats.txt"	, emit: statsCh

    script:
    """
    bcftools stats --threads ${task.cpus} ${vcf} > ${vcf.getSimpleName()}_stats.txt
    """
}




