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
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"

    input:
    tuple val(patient_id), path(queryVcf), path(queryIdx)
    tuple val(fileName), path(refVcf), path(refVcfIdx)
    
    output:
    tuple val(patient_id), path("${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz"), path("${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz.tbi") , emit: bcfAnnotCh

    script:

    """
    bcftools annotate --threads ${task.cpus} \\
    -a ${refVcf} -c ID \\
    -Oz -o ${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz ${queryVcf}
    
    bcftools index --tbi ${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz 
    """
}


