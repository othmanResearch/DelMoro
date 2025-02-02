// Module files for DelMoro pipeline

// Alignment based-reference

process alignReadsToRef {
    tag "ALIGNING GENOMES TO REFERENCE"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::bwa=0.7.18"
    container "firaszemzem/bwa-samtools:latest"

    input:
	path refGenome
	path indexes
	tuple val(patient_id), path(R1), path(R2)

    output:
       	path "${patient_id}_sor.bam" , emit : sorted_bam //  Sorted Bam file
       
    script:
    """
    bwa mem -t ${params.cpus} ${refGenome} ${R1} ${R2} \\
	| samtools view -Sb -@ ${params.cpus} \\
	| samtools sort -@ ${params.cpus}  -o ${patient_id}_sor.bam   
    """ 
}


process alignReadsToRefBWAMEM2 { 
    tag "ALIGNING GENOMES TO REFERENCE"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::bwa-mem2=2.2.1"
    container "firaszemzem/bwamem2-samtools:latest"
    
    input:
	path refGenome
	path indexes
	tuple val(patient_id), path(R1), path(R2)

    output:
	path "${patient_id}_sor.bam" , emit : sorted_bam //  Sorted Bam file
       
    script:
    """
    bwa-mem2 mem -t ${params.cpus} -M ${refGenome} ${R1} ${R2} \\
	| samtools view -Sb -@ ${params.cpus} \\
	| samtools sort -@ ${params.cpus}  -o ${patient_id}_sor.bam           
               
    """
}

// Assigning ReadGroups

process assignReadGroup {
    tag "ASSIGNING READ GROUPS"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "broadinstitute/gatk:latest"
 
    input:
	path aligned_bam
	//tuple val(patient_id), path(R1), path(R2)
         
    output:
	path "*@RG.bam" 	, emit : sorted_labeled_bam // Sorted_labeled bam file with RG

    script:
    """
    gatk AddOrReplaceReadGroups \\
        -I ${aligned_bam} \\
        -O ${aligned_bam.baseName}@RG.bam \\
        --RGID ${aligned_bam.baseName.takeWhile{ it != '_' }} \\
        --RGLB unspec \\
        --RGPL ILLUMINA \\
        --RGPU unspec \\
        --RGSM ${aligned_bam.baseName.takeWhile{ it != '_' }} \\
        --RGPM unspec \\
        --RGCN unspec
    """
}

// Marking Duplicates

process markDuplicates {
    tag "MARKING DUPLICATES"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "broadinstitute/gatk:latest"

    input:
	path sorted_bam
	// tuple val(patient_id), path(R1), path(R2)
    
    output:
	path "*@MD.bam" 	, emit : sorted_markduplicates_bam
	path "*.metrict"

    script:
    """
    gatk MarkDuplicates \\
    -I ${sorted_bam} \\
    -O ${sorted_bam.baseName}@MD.bam \\
    --METRICS_FILE ${sorted_bam.baseName}@MD.metrict \\
    --TMP_DIR .

    """
}

// Generating Indexes of Bam files

process IndexBam{
    tag "CREATING INDEX FOR BAM FILES"
    publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "firaszemzem/bwa-samtools:latest"
    
    input:
   	path BamFile 	  	// Bam file from sorted_markduplicates_bam

    output:
	path "${BamFile}.bai"		, emit: "IDXBAM"
    
    script:
    """
    samtools index \\
    -@ ${params.cpus} \\
    ${BamFile}
    """
}

process Extractregion {
    tag "EXTRACT REGION"
    publishDir "${params.outdir}/Mapping/", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "firaszemzem/bwa-samtools:latest"
 
    input:
	path BamFile		// Bam file from sorted_markduplicates_bam
    	path BamIdx

    output:
    	path "*.bam"

    script:
    """
    samtools view \\
    -@ ${params.cpus} \\
    -bh ${BamFile} ${params.region} > ${BamFile.baseName}_region_${params.region}.bam
    """
} 

// Generate Statictics before & after Marking Duplicates

process GenerateStat {
    tag "STATISCTICS FOR BAM-SAM FILES"
    publishDir "${params.outdir}/Mapping/BamMetrics", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "firaszemzem/bwa-samtools:latest"
    
    input:
	path sorted_labeled_bam
	path sorted_markduplicates_bam
    
    output:
  	path "*.flagstat"

    script:
    """
    samtools flagstat \\
    -@ ${params.cpus} \\
    ${sorted_labeled_bam} > ${sorted_labeled_bam}.flagstat
    
    samtools flagstat \\
    -@ ${params.cpus}  \\
    ${sorted_markduplicates_bam} > ${sorted_markduplicates_bam}.flagstat
    """
}




