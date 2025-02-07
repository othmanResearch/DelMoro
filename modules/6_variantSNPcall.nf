// Module files for DelMoro pipeline

// GATK variant calling for Recalibrated mapped reads  

process RecalHaploCall {
    tag "Recal Var Call with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    
    input:
	path ref
	path dic
	path fai
	tuple val(patient_id), path(ReclBamFile)
	path ReclBamBai
     
    output:
	path "*.vcf" , emit: "vcf_HaplotypeCaller_Recal"

    script:
    """
    gatk HaplotypeCaller \\
    	--native-pair-hmm-threads ${task.cpus} \\
  	--reference ${ref} \\
	--input ${ReclBamFile} \\
	--output ${ReclBamFile.baseName}.HC.vcf
    """
}

// Variant to Table  // to be visiualized with R 

process VarToTable {
    tag "Collect Variant in a Table using GATK4"
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    
    input:
	path Recalvcf	// vcf files from RecalHaploCAll
		
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
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'
  
    conda "bioconda::gatk4=4.4"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
		
    input:
	path variants
		
    output:
	path "${variants.baseName}.SNP.vcf"

    script:
    """
    gatk SelectVariants \\
 	--variant ${variants} \\
	--select-type-to-include SNP \\
	--output ${variants.baseName}.SNP.vcf
    """
}

// Create GVCF files

process  CreateGVCF{
    tag "CREATE GVCF with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'
  
    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    input:
	path ref
	path dic
	path fai
	tuple val(patient_id), path(ReclBamFile)
	path ReclBamBai

    output:
	path "*.g.vcf" , emit: "g_vcf_Recal"
	path "*.phased.bam" , emit: "phased_bam"

    script:
    """
    gatk HaplotypeCaller \\
	--native-pair-hmm-threads ${task.cpus} \\
	--reference ${ref} \\
	--input ${ReclBamFile} \\
	--output ${ReclBamFile.baseName}.g.vcf \\
	--bam-output ${ReclBamFile.baseName}.phased.bam \\
	--emit-ref-confidence GVCF
    """
}

// Generating Indexes of Gvcf Bam files

process IndexGVCF {
    tag "CREATING INDEX FOR Recalibrated BAM FILES"
    publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    
    input:
	path GVCFtoINDEX	// Gvcf file from g_vcf_Recal

    output:
	path "${GVCFtoINDEX}.idx"     	, emit: "IDXVCFiles"
    
    script:
    """
    gatk IndexFeatureFile \\
	--input ${GVCFtoINDEX} \\
	--output ${GVCFtoINDEX}.idx \\
     """
}

// Combining GVCFs 

process  CombineGvcfs{
    tag "COMBINE GVCF files with Gatk HaplotypeCaller"
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    
    input:
	path ref
	path dic
	path fai
	path GvcfFiles
	path IDXofGvcf

    output:
	path "Cohort.g.vcf" , emit: "CohorteVcf"

    script:
    """
    gatk CombineGVCFs \\
	--reference ${ref} \\
	--variant ${GvcfFiles.join(' --variant ')} \\
	--output Cohort.g.vcf
    """
}

// Generating Genotypes of GVCFs

process GenotypeGvcfs{
    tag "GENERATING GENOTYPES OF GVCF"
    publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' 	?
		"docker://broadinstitute/gatk:latest" 		:
		"broadinstitute/gatk:latest" 	}" 
    
    input:
	path ref
	path dic
	path fai
	path CombinedFile

    output:
	path "Cohort.g.Genotypes.vcf" , emit: "CombinedGENOTYPES"

    script:
    """
    gatk GenotypeGVCFs \\
	--reference ${ref} \\
	--variant ${CombinedFile} \\
	--output Cohort.g.Genotypes.vcf
    """
}

