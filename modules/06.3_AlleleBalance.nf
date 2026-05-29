// Module files for DelMoro pipeline

// ADD ALLELE BALANCE

process AlleleBalance {
    tag "ADD ALLELE BALANCE RaTIO FOR ${vcf}."
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"
        
    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)

    output:
    tuple val(patient_id), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz"), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz.{tbi,idx}")

    script:
    """
    bcftools +fill-tags -Oz -o \\
    ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz \\
    ${vcf} \\
    -- -t FORMAT/VAF

    tabix -p vcf ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz
    """
}

