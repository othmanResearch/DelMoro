// Module files for DelMoro pipeline

// GATK variant calling for raw mapped reads

process RawHaploCall {
	conda "bioconda::gatk4=4.4"
	tag "Raw Var Call with Gatk HaplotypeCaller"
    	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    	input:
       		path ref  
       		path dic
       		path fai
       		//path BamFile
       		tuple val(patient_id), path(BamFile)
       		path BamBai
     
    	output:
        	path "*raw.HC.vcf" , emit: "vcf_HaplotypeCaller_Raw" // HC : HaplotypeCaller
    	script:
        """
  	gatk HaplotypeCaller \\
  	  		--native-pair-hmm-threads ${params.cpus} \\
			--reference ${ref} \\
			--input ${BamFile} \\
			--output ${BamFile.baseName}.raw.HC.vcf 
       	"""
}
 
// BaseRecalibration 

process BaseRecalibrator {
	conda "bioconda::gatk4=4.4"
    	tag "CREATING TABLE FOR BQSR"
    	publishDir "${params.outdir}/Mapping", mode: 'copy'

    	input:
       		path ref  
       		path dic
       		path fai
       		//path sor_md_bam_file
       		tuple val(patient_id), path(sor_md_bam_file)
       		path knownsiteFile1
       		path IDXknsF1 		  // index of known site file n° x
       		path knownsiteFile2
       		path IDXkGCF
      
    	output:
        	path "*bqsr.table" , emit: "BQSR_Table"

    	script:
        """
  	gatk BaseRecalibrator \\
  			--reference ${ref} \\
  	  		--input ${sor_md_bam_file} \\
  	  		--known-sites ${knownsiteFile1} \\
  	  		--known-sites ${knownsiteFile2} \\
  	  		--output ${sor_md_bam_file}.bqsr.table
       """
}

// Apply base Recalibration 

process ApplyBQSR {
	conda "bioconda::gatk4=4.4"
	tag "APPLYING BASE QUALITY SCORE RECALIBRATION"
    	publishDir "${params.outdir}/Mapping", mode: 'copy'

    	input:
       		//path sor_md_bam_file 
       	    	tuple val(patient_id), path(sor_md_bam_file)
       		path bqsrTABLE
     
    	output:
        	path "*.recal.bam" , emit: "recal_bam"

    	script:
        """
  	gatk ApplyBQSR \\
  			--input ${sor_md_bam_file} \\
  			--bqsr-recal-file ${bqsrTABLE} \\
  			--output ${sor_md_bam_file}.recal.bam
       	"""
}  

// Generating Indexes of Recalibrated Bam files

process IndexRecalBam{
    	conda "bioconda::samtools=1.19"
    	tag "CREATING INDEX FOR Recalibrated BAM FILES"
    	publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

    	input:
        	path RecalBamFile	// Bam file from recal_bam

    	output:
        	path "${RecalBamFile}.bai"     	, emit: "IDXRECALBAM"
    
    	script:
        """
        samtools index -@ ${params.cpus}  ${RecalBamFile}  
       	"""
}

// GATK variant calling for Recalibrated mapped reads  // SNP  // same processes will be replicated using include {NameProcess as NameProcess1} from './modules/NameProcess

process RecalHaploCall {
	conda "bioconda::gatk4=4.4"
	tag "Recal Var Call with Gatk HaplotypeCaller"
    	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    	input:
       		path ref  
       		path dic
       		path fai
       		path ReclBamFile
       		path ReclBamBai
     
    	output:
        	path "*.vcf" , emit: "vcf_HaplotypeCaller_Recal"

    	script:
        """
  	gatk HaplotypeCaller \\
  			--native-pair-hmm-threads ${params.cpus} \\
			--reference ${ref} \\
			--input ${ReclBamFile} \\
			--output ${ReclBamFile.baseName}.HC.vcf 
       	"""
}

// Variant to Table  // to be visiualized with R 

process VarToTable {
	conda "bioconda::gatk4=4.4"
	tag "Collect Variant in a Table using GATK4"
	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'
	
	input:
		path Rawvcf	// vcf files from RawHaploCall 
		path Recalvcf	// vcf files from RecalHaploCAll
		
	output:
		path "${Rawvcf}.table"
		path "${Recalvcf}.table"	
	script:
	"""
	gatk VariantsToTable \\
			--fields CHROM -F POS -F TYPE -GF GT \\
			--variant ${Rawvcf} \\
			--output ${Rawvcf}.table
	gatk VariantsToTable \\
			--fields CHROM -F POS -F TYPE -GF GT \\
			--variant ${Recalvcf} \\
			--output ${Recalvcf}.table
	"""
}

// SNP Filtering from Gatk vcf outputs. 

process SnpFilter {
conda "bioconda::gatk4=4.4"
	tag "Collect Variant in a Table using GATK4"
	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'
	
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
	conda "bioconda::gatk4=4.4"
	tag "CREATE GVCF with Gatk HaplotypeCaller"
    	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    	input:
       		path ref  
       		path dic
       		path fai
       		path ReclBamFile
       		path ReclBamBai
       		//tuple val(patient_id), path(R1), path(R2)
     
    	output:
        	path "*.g.vcf" , emit: "g_vcf_Recal"
        	path "*.phased.bam" , emit: "phased_bam"
    	script:
        """
        gatk HaplotypeCaller \\
        		--native-pair-hmm-threads ${params.cpus} \\
   			--reference ${ref} \\
    			--input ${ReclBamFile} \\
    			--output ${ReclBamFile.baseName}.g.vcf \\
    			--bam-output ${ReclBamFile.baseName}.phased.bam \\
    			--emit-ref-confidence GVCF 
   
       	"""
}

// Generating Indexes of Gvcf Bam files

process IndexGVCF {
    	conda "bioconda::samtools=1.19"
    	tag "CREATING INDEX FOR Recalibrated BAM FILES"
    	publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

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
	conda "bioconda::gatk4=4.4"
	tag "COMBINE GVCF files with Gatk HaplotypeCaller"
    	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

    	input:
       		path ref  
       		path dic
       		path fai
       		path GvcfFiles
     		path IDXofGvcf
    	output:
        	path "Cohort.g.vcf" , emit: "Combinedvcf"
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
	conda "bioconda::gatk4=4.4"
	tag "GENERATING GENOTYPES OF GVCF"
    	publishDir "${params.outdir}/Mapping/Variants", mode: 'copy'

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

