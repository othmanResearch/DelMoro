// Module files for DelMoro pipeline
 
process IndexVcf {
    tag "CREATING INDEX FOR VCF FILES"
    publishDir "${params.outdir}/Variants/", mode: 'copy'

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

// Extract SNPs FROM RAW VCFs. 

process SNPSelect {
    tag "EXTRACT SNP "
    publishDir "${params.outdir}/Variants/", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants), path(indexes) 
//    tuple val(fileName), path (index)    			 
    
    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.SNP.vcf.gz") ,path("*.{idx,tbi}") , emit: vcfSnp  
    
    script:
    """
    gatk SelectVariants \\
 	--variant ${variants} \\
	--select-type-to-include SNP \\
	--output ${variants.getSimpleName()}.SNP.vcf.gz
    """
}

// Filter SNPs . 

process FilterSNP {
    tag "FILTER SNP for sample: ${variants}"

    publishDir "${params.outdir}/Variants/", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants), path(indexes)
 

    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.SNP.filtered.vcf.gz") ,path("*.{idx,tbi}")     , emit: filteredsnp


    script:
    """
    gatk VariantFiltration \\
        --variant ${variants} \\
        --filter-expression "QD < ${params.QD}" --filter-name "QD${params.QD}" \\
        --filter-expression "QUAL < ${params.QUAL}" --filter-name "QUAL${params.QUAL}" \\
        --filter-expression "SOR > ${params.SOR}" --filter-name "SOR${params.SOR}" \\
        --filter-expression "FS > ${params.FSSNP}" --filter-name "FS${params.FSSNP}" \\
        --filter-expression "MQ < ${params.MQ}" --filter-name "MQ${params.MQ}" \\
        --filter-expression "MQRankSum < ${params.MQRankSum}" --filter-name "MQRankSum-${params.MQRankSum}" \\
        --filter-expression "ReadPosRankSum < ${params.ReadPosRankSumSNP}" --filter-name "ReadPosRankSum-${params.ReadPosRankSumSNP}" \\
        --output ${variants.getSimpleName()}.SNP.filtered.vcf.gz
    """
}



// Extract INDELs FROM RAW VCFs. 

process INDELSelect {
    tag "EXTRACT INDEL"
    publishDir "${params.outdir}/Variants/", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants),  path(indexes)
    
    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.INDEL.vcf.gz")  ,path("*.{idx,tbi}")
 
    script:
    """
    gatk SelectVariants \\
 	--variant ${variants} \\
	--select-type-to-include INDEL \\
	--output ${variants.getSimpleName()}.INDEL.vcf.gz
    """
}

// Filter INDEL . 

process FilterINDEL {
    tag "FILTER INDEL for sample: ${variants}"

    publishDir "${params.outdir}/Variants/", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants), path(indexes)

    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.INDEL.filtered.vcf.gz") ,path("*.{idx,tbi}")      , emit: filteredindel

    script:
    """ 
    gatk VariantFiltration \\
        --variant ${variants} \\
        --filter-expression "QD < ${params.QD}" --filter-name "QD${params.QD}" \\
        --filter-expression "QUAL < ${params.QUAL}" --filter-name "QUAL${params.QUAL}" \\
        --filter-expression "FS > ${params.FSINDEL}" --filter-name "FS${params.FSINDEL}" \\
        --filter-expression "ReadPosRankSum < ${params.ReadPosRankSumINDEL}" --filter-name "ReadPosRankSum-${params.ReadPosRankSumINDEL}" \\
        --output ${variants.getSimpleName()}.INDEL.filtered.vcf.gz
    """
}

