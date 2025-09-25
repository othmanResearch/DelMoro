// Module files for DelMoro pipeline

// GATK variant calling for Recalibrated mapped reads  

process CallVariant {
    tag "Variant Calling with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile)
    path ReclBamBai

    output:
    tuple val(patient_id), path("${ReclBamFile.baseName}.HC.vcf.gz")	, emit: "CallVariantvcf"
    tuple val(patient_id), path("*.gz.tbi")				, emit: "CallVariantidx"

    script:
    """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.HC.vcf.gz

    tabix -f -p vcf ${ReclBamFile.baseName}.HC.vcf.gz
    """
}

// Create GVCF files

process CreateGVCF {
    tag "CREATE GVCF with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile)
    path ReclBamBai
    
    output:
    tuple val(patient_id), path("*.g.vcf.gz")	, emit: "g_vcf_Recal"
    tuple val(patient_id), path("*.phased.bam")	, emit: "phased_bam"
    tuple val(patient_id), path("*.gz.tbi")    	, emit: "CreateGVCFidx"

    script:
    """
    gatk HaplotypeCaller \\
	--native-pair-hmm-threads ${task.cpus} \\
	--reference ${ref} \\
	--input ${ReclBamFile} \\
	--output ${ReclBamFile.baseName}.g.vcf.gz \\
	--bam-output ${ReclBamFile.baseName}.phased.bam \\
	--emit-ref-confidence GVCF
	
    tabix -f -p vcf ${ReclBamFile.baseName}.g.vcf.gz
    """
}

// Generating Indexes of Gvcf Bam files

process IndexGVCF {
    tag "CREATING INDEX FOR Recalibrated BAM FILES"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path(GVCFtoINDEX)
    tuple val(patient_id), path(gzidx)
    
    output:
    tuple val(patient_id), path("${GVCFtoINDEX}.tbi"), emit: "IDXVCFiles"

    script:
    """
     tabix -f -p vcf ${GVCFtoINDEX} 
     """
}

 
// Combining GVCFs 

process CombineGvcfs {
    tag "COMBINE GVCF files with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(GvcfFiles)
    tuple val(patient_id), path(IDXofGvcf)
    
    output:
    tuple val(patient_id), path("Cohort.g.vcf.gz")	, emit: "CohortVcf"
    tuple val(patient_id), path("*.gz.tbi")    		, emit: "CombineGvcfsidx"
    
    script:
    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
	--output Cohort.g.vcf.gz

    tabix -f -p vcf Cohort.g.vcf.gz
    """
}

// Generating Genotypes of GVCFs

process GenotypeGvcfs {
    tag "GENERATING GENOTYPES OF GVCF"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(CombinedFile)
    tuple val(patient_id), path(gzidx)
    
    output:
    tuple val(patient_id), path("Cohort.g.Genotypes.vcf.gz")	, emit: "CombinedGENOTYPES"
    tuple val(patient_id), path("*.gz.tbi")    			, emit: "GenotypeGvcfsidx"
    
    script:
    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
	--output Cohort.g.Genotypes.vcf.gz
	
    tabix -f -p vcf Cohort.g.Genotypes.vcf.gz
    """
}
