// Module files for DelMoro pipeline

// Add DEFAULT IDs VCF

process AddVariantID {

    tag "ADD DEFAULT VARIANT IDs FOR ${vcf}"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter


    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"

    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)

    output:
    tuple val(patient_id),
        path("${vcf.getBaseName(2)}.id.vcf.gz"),
        path("${vcf.getBaseName(2)}.id.vcf.gz.{tbi,csi}")
        

    script:
    """
    bcftools annotate \\
        --set-id +'%CHROM\\_%POS\\_%REF\\_%FIRST_ALT' \\
        ${vcf} \\
        -Oz -o ${vcf.getBaseName(2)}.id.vcf.gz

    bcftools index --tbi ${vcf.getBaseName(2)}.id.vcf.gz
    """
}

// ANNOTATE VCF WITH BCFTOOLS
process RsAnnotation {
    tag "ADD VARIANS ID FROM ${refVcf} FOR ${patient_id}"
    publishDir (
        path : params.caller ? "${params.outdir}/Variants/deepvariant/" : "${params.outdir}/Variants/gatk/",
        mode: 'copy', 
        enabled: params.rsid != null
    )

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"

    input:
    tuple val(patient_id), path(queryVcf), path(queryIdx)
    tuple val(fileName), path(refVcf), path(refVcfIdx)
    
    output:
    tuple val(patient_id), 
        path("${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz"), 
        path("${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz.tbi") , emit: bcfAnnotCh

    script:
    """
    bcftools annotate --threads ${task.cpus} \\
    -a ${refVcf} -c ID \\
    -Oz -o ${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz ${queryVcf}
    
    bcftools index --tbi ${queryVcf.getBaseName(2)}_rs-${refVcf.getSimpleName()}.vcf.gz 
    """
}


