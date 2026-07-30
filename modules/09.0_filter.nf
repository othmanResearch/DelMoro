// Module files for DelMoro pipeline
 
// Extract SNPs FROM RAW VCFs. 

process SNPSelect {
    tag "EXTRACT SNP "
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy', enabled: params.keepinter 

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
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants), path(indexes)
 

    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.SNP.*filtered.vcf.gz") ,path("*.{idx,tbi}")     , emit: filteredsnp


    script:
    
    if ( params.strictFilter ) 
    """
    gatk VariantFiltration \\
        --variant ${variants} \\
        --genotype-filter-expression "GQ < ${params.GQ}" --genotype-filter-name "GQ${params.GQ}" \\
        --genotype-filter-expression "DP < ${params.DP}" --genotype-filter-name "DP${params.DP}" \\
        --genotype-filter-expression "(AB < ${params.ABmin} || AB > ${params.ABmax})" --genotype-filter-name "AB${params.ABmin}-${params.ABmax}" \\
        --filter-expression "QD < ${params.QD}" --filter-name "QD${params.QD}" \\
        --filter-expression "QUAL < ${params.QUAL}" --filter-name "QUAL${params.QUAL}" \\
        --filter-expression "SOR > ${params.SOR}" --filter-name "SOR${params.SOR}" \\
        --filter-expression "FS > ${params.FSSNP}" --filter-name "FS${params.FSSNP}" \\
        --filter-expression "MQ < ${params.MQ}" --filter-name "MQ${params.MQ}" \\
        --filter-expression "MQRankSum < ${params.MQRankSum}" --filter-name "MQRankSum-${params.MQRankSum}" \\
        --filter-expression "ReadPosRankSum < ${params.ReadPosRankSumSNP}" --filter-name "ReadPosRankSum-${params.ReadPosRankSumSNP}" \\
        --output ${variants.getSimpleName()}.SNP.strict-filtered.vcf.gz
    """
    else
    """
    gatk VariantFiltration \\
        --variant ${variants} \\
        --genotype-filter-expression "GQ < ${params.GQ}" --genotype-filter-name "GQ${params.GQ}" \\
        --genotype-filter-expression "DP < ${params.DP}" --genotype-filter-name "DP${params.DP}" \\
        --genotype-filter-expression "(AB < ${params.ABmin} || AB > ${params.ABmax})" --genotype-filter-name "AB${params.ABmin}-${params.ABmax}" \\
        --output ${variants.getSimpleName()}.SNP.filtered.vcf.gz
    """
}



// Extract INDELs FROM RAW VCFs. 

process INDELSelect {
    tag "EXTRACT INDEL"
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy', enabled: params.keepinter 

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
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(variants), path(indexes)

    output:
    tuple val(patient_id), path("${variants.getSimpleName()}.INDEL.*filtered.vcf.gz") ,path("*.{idx,tbi}")      , emit: filteredindel

    script:
    if ( params.strictFilter ) 
    """ 
    gatk VariantFiltration \\
        --variant ${variants} \\
        --genotype-filter-expression "GQ < ${params.GQ}" --genotype-filter-name "GQ${params.GQ}" \\
        --genotype-filter-expression "DP < ${params.DP}" --genotype-filter-name "DP${params.DP}" \\
        --genotype-filter-expression "(AB < ${params.ABmin} || AB > ${params.ABmax})" --genotype-filter-name "AB${params.ABmin}-${params.ABmax}" \\
        --filter-expression "QD < ${params.QD}" --filter-name "QD${params.QD}" \\
        --filter-expression "QUAL < ${params.QUAL}" --filter-name "QUAL${params.QUAL}" \\
        --filter-expression "FS > ${params.FSINDEL}" --filter-name "FS${params.FSINDEL}" \\
        --filter-expression "ReadPosRankSum < ${params.ReadPosRankSumINDEL}" --filter-name "ReadPosRankSum-${params.ReadPosRankSumINDEL}" \\
        --output ${variants.getSimpleName()}.INDEL.strict-filtered.vcf.gz
    """
    else
    """
    gatk VariantFiltration \\
        --variant ${variants} \\
        --genotype-filter-expression "GQ < ${params.GQ}" --genotype-filter-name "GQ${params.GQ}" \\
        --genotype-filter-expression "DP < ${params.DP}" --genotype-filter-name "DP${params.DP}" \\
        --genotype-filter-expression "(AB < ${params.ABmin} || AB > ${params.ABmax})" --genotype-filter-name "AB${params.ABmin}-${params.ABmax}" \\
        --output ${variants.getSimpleName()}.INDEL.filtered.vcf.gz
    """
}

process SortVCF {
    tag "SORT ${vcf}."
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"
        
    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)

    output:
    tuple val(patient_id), path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz"), path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz.{tbi,idx}")

    script:
    """
    bcftools sort -Oz -o ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz $vcf  
    tabix -p vcf ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz
    """
}



// Merge Filtered VCF

process mergeVCFs {
    tag "MERGE FILTERED VCFS"
    publishDir "${params.outdir}/Variants/filtered", mode: 'copy'
    
    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"

    input:
    tuple val(patient_id), path(snpsVcf), path(snpsIdx), path(indelsVcf), path(indelIdx)

    output:
    tuple val(patient_id), path("${patient_id}.filtered-merged.vcf.gz"), path("${patient_id}.filtered-merged.vcf.gz.{tbi,idx}")

    script:
    """
    bcftools concat -a -Oz \\
    -o ${patient_id}.filtered-merged.vcf.gz \\
    ${snpsVcf} ${indelsVcf}

    tabix -p vcf ${patient_id}.filtered-merged.vcf.gz
    """
}




