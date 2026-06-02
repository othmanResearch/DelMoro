// Module files for DelMoro pipeline

// GET SAMPLES NAME FROM COHORT VCF

process GetSamples {
	tag "GET SAMPLES NAME in ${vcf}"
	
	conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"
        
    input:
    tuple val(patient_id), path(vcf), path(tbi)

    output:
    tuple val(patient_id), path(vcf), path(tbi), stdout

    script:
    """
    bcftools query -l ${vcf}
    """
}

// SPLIT COHOTY VCF BY SAMPLES

process SplitBySample {

    tag "SPLIT ${sampleId} SAMPLE "
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }/SplittedSamples", mode: 'copy', enabled: params.splitSample
    
	conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"

    input:
    tuple  val(sampleId), path(vcf), path(tbi)

    output:
    tuple val(sampleId),
          path("${sampleId}_*.vcf.gz"),
          path("${sampleId}_*.vcf.gz.tbi"), emit: Samplevcf

    script:
    // Sanitize sample ID for use as a filename 
	def suffix = vcf.baseName.replaceFirst(/^[^_]+_/, '')
    """
    bcftools view \\
        --samples ${sampleId} \\
        --output-type u \\
        ${vcf} \\
    | bcftools view \\
        --min-ac 1 \\
        --output-type u \\
    | bcftools norm \\
        --rm-dup all \\
        --output-type z \\
        --output ${sampleId}_${suffix}.vcf.gz

    bcftools index --tbi ${sampleId}_${suffix}.vcf.gz
    """
    // Note on --min-ac 1:
    //   After subsetting to a single sample the ALT allele count at sites
    //   where this individual is HOM-REF drops to 0. --min-ac 1 discards
    //   those monomorphic sites so the individual VCF only carries variants
    //   that are actually present in that sample.
    //   Remove this filter if you want to keep all sites regardless.

    stub:
    """
    touch ${sampleId}.vcf.gz
    touch ${sampleId}.vcf.gz.tbi
    """
}


 
