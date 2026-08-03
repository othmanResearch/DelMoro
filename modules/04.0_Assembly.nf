// Module files for DelMoro pipeline

// Alignment based-reference

process AlignReadsToRef {
    tag "ALIGNING GENOMES TO REFERENCE"
    publishDir "${params.outdir}/Mapping", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::bwa=0.7.18 bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'
	? "docker://firaszemzem/bwa-samtools:latest"  	
    	: "firaszemzem/bwa-samtools:latest"}"

    input:
    path refGenome
    path indexes
    tuple val(patient_id), path(R1), path(R2)

    output:
    tuple val(patient_id), path("${patient_id}_sor.bam"), emit: sorted_bam

    script:
    """
    bwa mem -t ${task.cpus} ${refGenome} ${R1} ${R2} \\
	| samtools view -Sb -@ ${task.cpus} \\
	| samtools sort -@ ${task.cpus}  -o ${patient_id}_sor.bam
    """
}


process AlignReadsToRefBwaMem2 {
    tag "ALIGNING GENOMES TO REFERENCE"
    publishDir "${params.outdir}/Mapping", mode: 'copy', enabled: params.keepinter 

    conda "bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'	
	? "docker://firaszemzem/bwamem2-samtools:latest" 
	: "firaszemzem/bwamem2-samtools:latest"}"

    input:
    path refGenome
    path indexes
    tuple val(patient_id), path(R1), path(R2)

    output:
    tuple val(patient_id), path("${patient_id}_sor.bam") , emit: sorted_bam

    script:
    """
    bwa-mem2 mem -t ${task.cpus} -M ${refGenome} ${R1} ${R2} \\
	| samtools view -Sb -@ ${task.cpus} \\
	| samtools sort -@ ${task.cpus}  -o ${patient_id}_sor.bam
    """
}

// Assigning ReadGroups

process AssignReadGroup {
    tag "ASSIGNING READ GROUPS"
    publishDir "${params.outdir}/Mapping", mode: 'copy', enabled: params.keepinter

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'	
    	? "docker://broadinstitute/gatk:latest"	
    	: "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path (aligned_bam)

    output:
    tuple val(patient_id), path ("*_RG.bam") , emit: sorted_labeled_bam

    script:
    """
    gatk AddOrReplaceReadGroups \\
        -I ${aligned_bam} \\
        -O ${aligned_bam.baseName}_RG.bam \\
        --RGID ${aligned_bam.baseName.takeWhile { it != '_' }} \\
        --RGLB unspec \\
        --RGPL ILLUMINA \\
        --RGPU unspec \\
        --RGSM ${aligned_bam.baseName.takeWhile { it != '_' }} \\
        --RGPM unspec \\
        --RGCN unspec
    """
}

// Marking Duplicates

process MarkDuplicates {
    tag "MARKING DUPLICATES"
    publishDir "${params.outdir}/Mapping", mode: 'copy'

    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    tuple val(patient_id), path (sorted_bam)

    output:
    tuple val(patient_id), path ("*_delMoro.bam"), emit: sorted_markduplicates_bam
    tuple val(patient_id), path ("*.metrict")

    script:
    """
    gatk MarkDuplicates \\
    -I ${sorted_bam} \\
    -O ${sorted_bam.baseName.takeWhile{ it != '_' }}_delMoro.bam \\
    --METRICS_FILE ${sorted_bam.baseName.takeWhile{ it != '_' }}_MD.metrict \\
    --TMP_DIR .

    """
}
//
// Generating Indexes of Bam files

process IndexBam {
    tag "CREATING INDEX FOR BAM FILES"
    publishDir "${params.outdir}/Mapping/", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwa-samtools:latest"
        : "firaszemzem/bwa-samtools:latest"}"

    input:
    tuple val(patient_id), path (BamFile)

    output:
    tuple val(patient_id), path ("${BamFile}.bai"), emit: "IDXBAM"

    script:
    """
    samtools index \\
    -@ ${task.cpus} \\
    ${BamFile}
    """
}

// Generate Statictics before & after Marking Duplicates

process GenerateStat {
    tag "STATISCTICS FOR BAM-SAM FILES"
    publishDir "${params.outdir}/Mapping/BamMetrics", mode: 'copy'

    conda "bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwa-samtools:latest"
        : "firaszemzem/bwa-samtools:latest"}"

    input:
    tuple val(patient_id), path (sorted_labeled_bam)
    tuple val(patientid), path (sorted_markduplicates_bam)

    output:
    tuple val(patient_id), path ("*.flagstat")

    script:
    """
    samtools flagstat \\
    -@ ${task.cpus} \\
    ${sorted_labeled_bam} > ${sorted_labeled_bam}.flagstat
    
    samtools flagstat \\
    -@ ${task.cpus}  \\
    ${sorted_markduplicates_bam} > ${sorted_markduplicates_bam}.flagstat
    """
}
