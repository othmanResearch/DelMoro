// Module files for DelMoro pipeline

// GATK variant calling for Recalibrated mapped reads  

process RecalHaploCall {
    tag "Recal Var Call with Gatk HaplotypeCaller"
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
    path "${ReclBamFile.baseName}.HC.vcf.gz"	, emit: "vcf_HaplotypeCaller_Recal"
    path "*.gz.tbi"				, emit: "RecalHaploCallidx"

    script:
    """
    gatk HaplotypeCaller \\
        --native-pair-hmm-threads ${task.cpus} \\
        --reference ${ref} \\
        --input ${ReclBamFile} \\
        --output ${ReclBamFile.baseName}.HC.vcf.gz

    tabix -f -p vcf ${ReclBamFile.baseName}.HC.vcf.gz
    """
}


// Variant to Table  // to be visiualized with R 

process VarToTable {
    tag "Collect Variant in a Table using GATK4"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path Recalvcf
    path gzidx
    
    output:
    path "${Recalvcf}.table"

    script:
    """
    gatk VariantsToTable \\
	--fields CHROM -F POS -F TYPE -GF GT \\
	--variant ${Recalvcf} \\
	--output ${Recalvcf}.table
    """
}

// SNP Filtering from Gatk vcf outputs. 

process SnpFilter {
    tag "Collect SNP in a Table using GATK4"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path variants
    path gzidx
    
    output:
    path "${variants.baseName}.SNP.vcf.gz"
    path "*.gz.tbi"	 , emit: "SnpFilteridx"

    script:
    """
    gatk SelectVariants \\
 	--variant ${variants} \\
	--select-type-to-include SNP \\
	--output ${variants.baseName}.SNP.vcf.gz
	
    tabix -f -p vcf ${variants.baseName}.SNP.vcf.gz
    """
}

// Create GVCF files

process CreateGVCF {
    tag "CREATE GVCF with Gatk HaplotypeCaller"
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
    path "*.g.vcf.gz"	, emit: "g_vcf_Recal"
    path "*.phased.bam"	, emit: "phased_bam"
    path "*.gz.tbi"    	, emit: "CreateGVCFidx"

    script:
    """
    gatk HaplotypeCaller \\
	--native-pair-hmm-threads ${task.cpus} \\
	--reference ${ref} \\
	--input ${ReclBamFile} \\
	--output ${ReclBamFile.baseName}.g.vcf.gz \\
	--bam-output ${ReclBamFile.baseName}.phased.bam \\
	--emit-ref-confidence GVCF
	
    tabix -f -p vcf ${ReclBamFile.baseName}.g.vcf.gz
    """
}

// Generating Indexes of Gvcf Bam files

process IndexGVCF {
    tag "CREATING INDEX FOR Recalibrated BAM FILES"
    publishDir "${params.outdir}/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path GVCFtoINDEX
    path gzidx
    
    output:
    path "${GVCFtoINDEX}.tbi", emit: "IDXVCFiles"

    script:
    """
     tabix -f -p vcf ${GVCFtoINDEX} 
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
    path GvcfFiles
    path IDXofGvcf
    
    output:
    path "Cohort.g.vcf.gz"	, emit: "CohortVcf"
    path "*.gz.tbi"    		, emit: "CombineGvcfsidx"
    
    script:
    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
	--output Cohort.g.vcf.gz

    tabix -f -p vcf Cohort.g.vcf.gz
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
    path CombinedFile
    path gzidx
    
    output:
    path "Cohort.g.Genotypes.vcf.gz"	, emit: "CombinedGENOTYPES"
    path "*.gz.tbi"    			, emit: "GenotypeGvcfsidx"
    
    script:
    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
	--output Cohort.g.Genotypes.vcf.gz
	
    tabix -f -p vcf Cohort.g.Genotypes.vcf.gz
    """
}



