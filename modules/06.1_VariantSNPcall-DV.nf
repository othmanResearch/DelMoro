// Module files for DelMoro pipeline

// Variant Calling with DeepVariant 

process deepVariant {
    tag "Variant Calling with DEEPVARIANT"
    publishDir "${params.outdir}/Variants/deepvariant", mode: 'copy'

    container "${workflow.containerEngine == 'singularity'
        ? "docker://google/deepvariant:1.9.0"
        : "google/deepvariant:1.9.0"}"

    input:
    path ref
    path dic
    path fai
    tuple val(patient_id), path(bamFile), path(Bamidx)
    path bedtarget
    
    output:
    tuple val(patient_id), path("${bamFile.baseName}.*.DV.vcf.gz"), path("${bamFile.baseName}.*.DV.vcf.gz.{tbi,idx}") , emit: "CallVariantvcf"
    tuple val(patient_id), path("${bamFile.baseName}.*.DV.visual_report.html") 
    tuple val(patient_id), path("${bamFile.baseName}.*.DV.g.vcf.gz"), path("${bamFile.baseName}.*.DV.g.vcf.gz.{tbi,idx}") , optional: true  , emit: "deepGvcf" 
    
    script:
    def intervals = params.region ?: ""
    def regionTag = params.region ? params.region.split(':')[0] : "full"
    def gvcfArg = (params.mode == 'cohort') ? "--output_gvcf=${bamFile.baseName}.${regionTag}.DV.g.vcf.gz" : ""
	
    """
    /opt/deepvariant/bin/run_deepvariant \\
    --model_type=${params.modelType} \\
    --vcf_stats_report=true \\
    --ref=${ref} \\
    --reads=${bamFile} \\
    --output_vcf=${bamFile.baseName}.${regionTag}.DV.vcf.gz \\
    ${gvcfArg} \\
    --num_shards=${task.cpus} \\
    ${intervals ? "--regions ${intervals}" : ""}
    """
}


process glnexus {
    tag "COMBINE GVCF files with GLNEXUS"
    publishDir "${params.outdir}/Variants/deepvariant", mode: 'copy'
	
    conda "bioconda::glnexus=1.4.1"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://ghcr.io/dnanexus-rnd/glnexus:v1.4.1"
        : "ghcr.io/dnanexus-rnd/glnexus:v1.4.1"}"


    input:
    tuple val(patient_id), path(gvcfs), path(gvcfIDX)

    output:
    tuple val(patient_id), path("cohort_delMoro-*.vcf.gz"), path("*.{tbi,idx}")	, emit: "cohortDeepVcf"
    
    script:
    def regionTag = params.region ? params.region.split(':')[0] : "full"

    """
    glnexus_cli --threads ${task.cpus} \\
    --config DeepVariant \\
    ${gvcfs} \\
    | bcftools view -Oz -o  cohort_delMoro-${regionTag}.vcf.gz

    tabix -p vcf  cohort_delMoro-${regionTag}.vcf.gz
    """
}


   
