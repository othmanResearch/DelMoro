// Module files for DelMoro pipeline
    
// ANNOTATE VCF WITH BCFTOOLS
process RsAnnotation {
    tag "ADD VARIANS ID FOR ${patient_id}"
    publishDir (
        path : params.caller ? "${params.outdir}/Variants/deepvariant/" : "${params.outdir}/Variants/gatk/",
        mode: 'copy'
    )

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? 'docker://staphb/bcftools:latest'
        : 'staphb/bcftools:latest'}"

    input:
    tuple val(patient_id), path(queryVcf), path(queryIdx)
    tuple val(fileName), path(refVcf), path(refVcfIdx)
    
    output:
    tuple val(patient_id), path("${patient_id}_delMoro_rs-${refVcf.getSimpleName()}.vcf.gz"), path("${patient_id}_delMoro_rs-${refVcf.getSimpleName()}.vcf.gz.tbi") , emit: bcfAnnotCh

    script:

    """
    bcftools annotate --threads ${task.cpus} \\
    -a ${refVcf} -c ID \\
    -Oz -o ${patient_id}_delMoro_rs-${refVcf.getSimpleName()}.vcf.gz ${queryVcf}
    
    gatk IndexFeatureFile --input ${patient_id}_delMoro_rs-${refVcf.getSimpleName()}.vcf.gz 
    """
}


