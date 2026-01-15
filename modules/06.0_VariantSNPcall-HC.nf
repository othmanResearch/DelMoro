// Module files for DelMoro pipeline

// GATK variant calling for Recalibrated mapped reads  

process CallVariant {
    tag "Variant Calling with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/gatk", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile), path(Bamidx)

    output:
    tuple val(patient_id), path("${ReclBamFile.baseName}.*.HC.vcf.gz"), path("*.{tbi,idx}") , emit: "CallVariantvcf"

    script:
    // Ternary-based interval selection
    def intervals = params.region ? params.region : ""

    // Output label
    def region_tag = params.region ? params.region.split(':')[0] : "full"
    """                              
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.${region_tag}.HC.vcf.gz \\
        ${intervals ? "-L ${intervals}" : ""}
    """
}

// Create GVCF files

process CreateGVCF {
    tag "CREATE GVCF with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/gatk", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile), path(Bamidx)
    
    output:
    tuple val(patient_id), path("*.g.vcf.gz"), path("*.{tbi,idx}")	, emit: "g_vcf_Recal"

    script:
    // Ternary-based interval selection
    def intervals = params.region ? params.region : ""

    // Output label
    def region_tag = params.region ? params.region.split(':')[0] : "full"
       
    """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.${region_tag}.g.vcf.gz \\
        --emit-ref-confidence GVCF \\
        ${intervals ? "-L ${intervals}" : ""}
    """
}


 
// Combining GVCFs 

process CombineGvcfs {
    tag "COMBINE GVCF files with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/gatk", mode: 'copy'

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
    tuple val(patient_id), path("cohort_delMoro-*.g.vcf.gz"), path("*.{tbi,idx}"), emit: "CohortVcf"
    
    script:
    // Determine region tag (match previous logic)
    def region_tag = params.region ? params.region.split(':')[0] : "full"

    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
        --output cohort_delMoro-${region_tag}.g.vcf.gz
    """
}
 




// Generating Genotypes of GVCFs

process GenotypeGvcfs {
    tag "GENERATING GENOTYPES OF GVCF"
    publishDir "${params.outdir}/Variants/gatk", mode: 'copy'

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
    tuple val(patient_id), path("cohort_delMoro-*.vcf.gz"), path("*.{tbi,idx}")	, emit: "CombinedGENOTYPES"
    
    script:
    // Determine region tag (same as previous processes)
    def region_tag = params.region ? params.region.split(':')[0] : "full"

    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
        --output cohort_delMoro-${region_tag}.vcf.gz
    """
}

