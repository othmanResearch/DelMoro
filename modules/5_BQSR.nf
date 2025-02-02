// Module files for DelMoro pipeline

process DownloadKns1 {
    tag "Downloading ${params.ivcf1}"
    publishDir "./knownsites/${params.ivcf1}/", mode: 'copy'
    
    conda "conda-forge::awscli=2.23.6"
    container "xueshanf/awscli:alpine-3.16"
    
    output:
	path "*", emit: igenome_ch

    script:
    def filename = "${params.IVCF[params.ivcf1].vcf.tokenize('/').last()}"
	
    """
    aws s3 cp --no-sign-request \\
	--region eu-west-1 ${params.IVCF[params.ivcf1].vcf} ./

    if [[ "${filename}" == *.gz ]]; then
	gunzip "${filename}"
    fi
    """
}
 
process DownloadKns2 {
    tag "Downloading ${params.ivcf2}"
    publishDir "./knownsites/${params.ivcf2}/", mode: 'copy'
 
    conda "conda-forge::awscli=2.23.6"   
    container "xueshanf/awscli:alpine-3.16"
    
    output:
        path "*", emit: igenome_ch

    script:
	def filename = "${params.IVCF[params.ivcf2].vcf.tokenize('/').last()}"
    
    """ 
    aws s3 cp --no-sign-request \\
    --region eu-west-1 ${params.IVCF[params.ivcf2].vcf} ./

    if [[ "${filename}" == *.gz ]]; then
        gunzip "${filename}"
    fi
    """
}
 
// indexing known sites files 

process IndexKNownSites {
    tag "CREATING INDEX for known sites vcf"
    publishDir "${params.outdir}/Indexes/knownSites", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "broadinstitute/gatk:latest"

    input:
	path kn_site_File 	  // known Sites file n°1 related to params.knwonSite1
	//path kn_site_File2 	  // known Sites file n°2 related to params.knwonSite2

    output:
   	path "${kn_site_File}.idx"	//, emit: "IDXknS1"
	//path "${kn_site_File2}.idx"     , emit: "IDXknS2"
    
    script:
    """
    gatk IndexFeatureFile \\
	--input ${kn_site_File} \\
	--output ${kn_site_File}.idx
    """
}
 
// BaseRecalibration 

process BaseRecalibrator {
    tag "CREATING TABLE FOR BQSR"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "broadinstitute/gatk:latest"
    
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
    tag "APPLYING BASE QUALITY SCORE RECALIBRATION"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4.0.0"
    container "broadinstitute/gatk:latest"
    
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
    tag "CREATING INDEX FOR Recalibrated BAM FILES"
    publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "firaszemzem/bwa-samtools:latest"
    
    input:
	path RecalBamFile	// Bam file from recal_bam

    output:
    	path "${RecalBamFile}.bai"     	, emit: "IDXRECALBAM"
    
    script:
    """
    samtools index -@ ${params.cpus}  ${RecalBamFile}
    """
}
 
