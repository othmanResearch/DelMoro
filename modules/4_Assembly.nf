// Module files for DelMoro pipeline

// Alignment based-reference


process alignReadsToRef {
	conda "bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.21"
    	tag "ALIGNING GENOMES TO REFERENCE"
    	publishDir "${params.outdir}/Mapping", mode: 'copy'

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
	conda "bioconda::picard=3.2.0"
    	tag "ASSIGNING READ GROUPS"
    	publishDir "${params.outdir}/Mapping", mode: 'copy'
    
    	input:
        	path aligned_bam
        	//tuple val(patient_id), path(R1), path(R2)
         
    	output:
        	path "*@RG.bam" 	, emit : sorted_labeled_bam // Sorted_labeled bam file with RG

    	script: 
    	"""
	picard AddOrReplaceReadGroups \\
        		-I ${aligned_bam} \\
                        -O ${aligned_bam.baseName}@RG.bam \\
                        -RGID ${aligned_bam.baseName.takeWhile{ it != '_' }} \\
                        -RGLB unspec \\
                        -RGPL ILLUMINA \\
                        -RGPU unspec \\
                        -RGSM ${aligned_bam.baseName.takeWhile{ it != '_' }} \\
                        -RGPM unspec \\
                        -RGCN unspec
     	"""   
}

// Marking Duplicates

process markDuplicates {
	conda "bioconda::picard=3.2.0"
	tag "MARKING DUPLICATES"
    	publishDir "${params.outdir}/Mapping", mode: 'copy'
    
    	input: 
    	    path sorted_bam
    	//    tuple val(patient_id), path(R1), path(R2)
    
    	output:
    	    path "*@MD.bam" 	, emit : sorted_markduplicates_bam
    	    path "*.metrict"

    	script:
    	"""
    	picard MarkDuplicates --INPUT ${sorted_bam} \\
        		--OUTPUT ${sorted_bam.baseName}@MD.bam \\
                        --METRICS_FILE ${sorted_bam.baseName}@MD.metrict \\
                        --TMP_DIR . 
    	"""       
}
// Generating Indexes of Bam files

process IndexBam{
    	conda "bioconda::samtools=1.21"
    	tag "CREATING INDEX FOR BAM FILES"
    	publishDir "${params.outdir}/Indexes/BamFiles", mode: 'copy'

    	input:
        	path BamFile 	  	// Bam file from sorted_markduplicates_bam 

    	output:
        	path "${BamFile}.bai"		, emit: "IDXBAM" 
    
    	script:
        """
        samtools index -@ ${params.cpus}  ${BamFile}  

       	"""
}

process Extractregion { 
	conda "bioconda::samtools=1.21"
    	tag "EXTRACT REGION"
    	publishDir "${params.outdir}/Mapping/", mode: 'copy'
    
    	input:
        	path BamFile		// Bam file from sorted_markduplicates_bam 
        	path BamIdx

    	output:                        
        	path "*.bam"

    	script: 
    	""" 
    	samtools view -@ {params.cpus} -bh ${BamFile} ${params.region} > ${BamFile.baseName}_region_${params.region}.bam
    	"""
} 
// Generate Statictics before & after Marking Duplicates

process GenerateStat {
    	conda "bioconda::samtools=1.21"
    	tag "STATISCTICS FOR BAM-SAM FILES"
    	publishDir "${params.outdir}/Mapping/Metrics", mode: 'copy'
    	
    	input:
      		path sorted_labeled_bam
      		path sorted_markduplicates_bam
    
    	output:
     		path "*.flagstat" 

    	script: 
    	"""
      	samtools flagstat -@ {params.cpus} ${sorted_labeled_bam} > ${sorted_labeled_bam}.flagstat
      	samtools flagstat -@ {params.cpus}  ${sorted_markduplicates_bam} >  ${sorted_markduplicates_bam}.flagstat
    	"""
}




