// Module files for DelMoro pipeline

// Sort VCF 

process SortVCF {
    tag "SORT ${vcf}."
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"
        
    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)

    output:
    tuple val(patient_id), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz"), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz.{tbi,idx}")

    script:
    """
    bcftools sort -Oz -o ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz $vcf  
    tabix -p vcf ${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.sorted.vcf.gz
    """
}

// Normalize and split multiallelic VCF

process NormalizeVCF {
    tag "SPLIT MULTI ALLELES FOR ${vcf}"
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy',  enabled: (params.splitAllele != null && params.rsid == null )
    
    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? 'docker://firaszemzem/bcftools:1.21'
        : 'firaszemzem/bcftools:1.21'}"

    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)
    path reference
    path dict
    path fai

    output:
    tuple val(patient_id),
        path("${vcf.getBaseName(vcf.name.endsWith('.gz') ? 2 : 1)}.norm.vcf.gz"),
        path("${vcf.getBaseName(vcf.name.endsWith('.gz') ? 2 : 1)}.norm.vcf.gz.{tbi,csi}")

    script:
    """
    bcftools norm \\
        --threads ${task.cpus} \\
        --fasta-ref ${reference} \\
        --multiallelics -any \\
        --atomize \\
        --rm-dup all \\
        --atom-overlaps '*' \\
        --check-ref w \\
        --keep-sum AD \\
        --output-type z \\
        --output ${vcf.getBaseName(vcf.name.endsWith('.gz') ? 2 : 1)}.norm.vcf.gz \\
        --write-index \\
        ${vcf}
    """
}


