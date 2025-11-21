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
    tuple val(patient_id), path("${ReclBamFile.baseName}.HC.vcf.gz"), path("*.{tbi,idx}") , emit: "CallVariantvcf"

    script:
    """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.HC.vcf.gz
    """
}

// Create GVCF files

process CreateGVCF {
    tag "CREATE GVCF with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants", mode: 'copy', enabled: params.keepinter 

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
    tuple val(patient_id), path("*.g.vcf.gz"), path("*.{tbi,idx}")	, emit: "g_vcf_Recal"

    script:
    """
    gatk HaplotypeCaller \\
	--native-pair-hmm-threads ${task.cpus} \\
	--reference ${ref} \\
	--input ${ReclBamFile} \\
	--output ${ReclBamFile.baseName}.g.vcf.gz \\
	--emit-ref-confidence GVCF
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
    tuple val(patient_id), path(GvcfFiles), path(IDXofGvcf)
    
    output:
    tuple val(patient_id), path("cohort_delMoro-g.vcf.gz"), path("*.{tbi,idx}")	, emit: "CohortVcf"
    
    script:
    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
	--output cohort_delMoro-g.vcf.gz
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
    tuple val(patient_id), path(CombinedFile), path(gzidx)
    
    output:
    tuple val(patient_id), path("cohort_delMoro.vcf.gz"), path("*.{tbi,idx}")	, emit: "CombinedGENOTYPES"
    
    script:
    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
	--output cohort_delMoro.vcf.gz
    """
}
