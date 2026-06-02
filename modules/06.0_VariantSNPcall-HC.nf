// Module files for DelMoro pipeline

// GATK variant calling for Recalibrated mapped reads  

process CallVariant {

    tag "Variant Calling with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile), path(Bamidx)
    path bedtarget


    output:
    tuple val(patient_id),
          path("${ReclBamFile.baseName}.*.HC.vcf.gz"),
          path("*.{tbi,idx}"),
          emit: "CallVariantvcf"

    script:
    def hasBed    = bedtarget.name != 'NO_FILE'
    def hasRegion = params.region != null

    def regions = hasRegion ? (params.region instanceof List ? params.region : params.region.split(','))  : []

    def intervalArg = hasBed  ? "-L ${bedtarget}" : hasRegion ? regions.collect { "-L $it" }.join(' ') : ""
    def regionTag   = hasBed  ? "bedtargeted"     : hasRegion ? regions.collect { it.split(':')[0] }.join('_')  : "full"

   """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        -R ${ref} \\
        -I ${ReclBamFile} \\
        -O ${ReclBamFile.baseName}.${regionTag}.HC.vcf.gz \\
        ${intervalArg}
    """

}

// Create GVCF files

process CreateGVCF {
    tag "CREATE GVCF with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(ReclBamFile), path(Bamidx)
    path bedtarget
    
    output:
    tuple val(patient_id), path("*.g.vcf.gz"), path("*.{tbi,idx}")	, emit: "g_vcf_Recal"

    script:
    def hasBed = bedtarget.name != 'NO_FILE'
    def hasRegion = params.region != null

    def intervalArg = hasBed ? "-L ${bedtarget}"  : hasRegion ? "-L ${params.region}"       : ""
    def regionTag   = hasBed ? "bedtargeted"      : hasRegion ? params.region.split(':')[0] : "full"

    """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.${regionTag}.g.vcf.gz \\
        --emit-ref-confidence GVCF \\
        ${intervalArg}
    """
}

// Combining GVCFs 

process CombineGvcfs {
    tag "COMBINE GVCF files with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter

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
    def regionTag   = params.bedtarget ? "bedtargeted"      : params.region ? params.region.split(':')[0] : "full"
    
    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
        --output cohort_delMoro-${regionTag}.g.vcf.gz
    """
}
 
// Generating Genotypes of GVCFs

process GenotypeGvcfs {
    tag "GENERATING GENOTYPES OF GVCF"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter

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
    
    def regionTag   = params.bedtarget ? "bedtargeted"      : params.region ? params.region.split(':')[0] : "full"

    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
        --output cohort_delMoro-${regionTag}.vcf.gz
    """
}

