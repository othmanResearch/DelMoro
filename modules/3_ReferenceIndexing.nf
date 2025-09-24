// Module files for DelMoro pipeline


//         RETRIEVE IGENOMES
////////////////////////////////////////////////////

process DownloadIgenomes {
    tag "Downloading ${params.igenome} from iGenomes reference ${params.IGENOMES[params.igenome]}"
    publishDir "./Reference_Genome/", mode: 'copy'
    storeDir "./Reference_Genome/"

    conda "conda-forge::awscli=2.23.6"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://xueshanf/awscli:alpine-3.16"
        : "xueshanf/awscli:alpine-3.16"}"

    output:
    path "./genome${params.igenome}.fa", emit: "igenome_ch"

    script:
    """
    aws s3 cp --no-sign-request --region eu-west-1 \\
    ${params.IGENOMES[params.igenome].fasta} \\
    ./genome${params.igenome}.fa
    """
}


// 	CREATING INDEX FOR ALINGER
////////////////////////////////////////////////////

process CreateIndex {
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA"
    publishDir "./Reference_Genome/", mode: 'copy', overwrite: false
    storeDir "./Reference_Genome/"
    
    conda "bioconda::bwa=0.7.18"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwa-samtools:latest"
        : "firaszemzem/bwa-samtools:latest"}"

    input:
    path ref

    output:
    path "*.{amb,ann,bwt,pac,sa}", emit: "bwaIndex"

    script:
    """
    bwa index ${ref}               
    """
}

process CreateIndexBwaMem2 {
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA-MEM2"
    publishDir "./Reference_Genome/", mode: 'copy', overwrite: false
    storeDir "./Reference_Genome/"
    
    conda "bioconda::bwa-mem2=2.2.1"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwamem2-samtools:latest"
        : "firaszemzem/bwamem2-samtools:latest"}"

    input:
    path ref

    output:
    path "*.{0123,amb,ann,bwt.2bit.64,pac}", emit: "bwaIndex"

    script:
    """
    bwa-mem2 index ${ref}               
    """
}

////////////////////////////////////////////////////
//	CREATING DICTIONARY FOR REF GENOME FOR ALIGNER

process CreateDictionary {
    tag "GENERATE DICTIONARY"
    publishDir "./Reference_Genome/", mode: 'copy', overwrite: false
    storeDir "./Reference_Genome/"
    
    conda "bioconda::gatk4=4.4"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://broadinstitute/gatk:latest"
        : "broadinstitute/gatk:latest"}"

    input:
    path ref

    output:
    path "*.dict", emit: "gatkDict"

    script:
    """
    gatk CreateSequenceDictionary --REFERENCE ${ref}
    """
}


////////////////////////////////////////////////////
//	CREATING INDEX BY SAMTOOLS

process CreateIndexSamtools {
    tag "GENERATE INDEX BY SAMTOOLS"
    publishDir "./Reference_Genome/", mode: 'copy', overwrite: false
    storeDir "./Reference_Genome/"
    
    conda "bioconda::samtools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bwa-samtools:latest"
        : "firaszemzem/bwa-samtools:latest"}"

    input:
    path ref

    output:
    path "*.fai", emit: "samtoolsIndex"

    script:
    """
    samtools faidx ${ref}  --output ${ref}.fai                         
    """
}
