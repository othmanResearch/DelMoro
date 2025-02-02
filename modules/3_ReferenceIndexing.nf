// Module files for DelMoro pipeline


//         RETRIEVE IGENOMES
////////////////////////////////////////////////////
 
process DownloadIgenomes {
    tag "Downloading ${params.igenome} from iGenomes reference ${params.IGENOMES[params.igenome]}"
    publishDir "./Reference_Genome/", mode: 'copy'
 
    conda "conda-forge::awscli=2.23.6"
    container "xueshanf/awscli:alpine-3.16"

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

process createIndex {
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA"
    publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false

    conda "bioconda::bwa=0.7.18"
    container "firaszemzem/bwa-samtools:latest"
    
    input:
	path ref
         
    output:
        path "*.{amb,ann,bwt,pac,sa}" 	, emit: "bwa_index"

    script: 
    """
    bwa index ${ref}               
    """ 
}

process createIndexBWAMEM2 { 
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA-MEM2"
    publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false
    
    conda "bioconda::bwa-mem2=2.2.1"
    container "firaszemzem/bwamem2-samtools:latest"
    
    input:
	path ref
     		
    output:
	path "*.{0123,amb,ann,bwt.2bit.64,pac}"	, emit: "bwa_index"
	
    script:
    """
    bwa-mem2 index ${ref}               
    """
}

////////////////////////////////////////////////////
//	CREATING DICTIONARY FOR REF GENOME FOR ALIGNER

process createDictionary {
    tag "GENERATE DICTIONARY"
    publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false
    
    conda "bioconda::gatk4=4.4"
    container "broadinstitute/gatk:latest"
    
    input:
	    path ref
     		
    output:
	    path "*.dict"   ,   emit: "gatk_dic"

    script:
    """
    gatk CreateSequenceDictionary --REFERENCE ${ref}
    """
}


////////////////////////////////////////////////////
//	CREATING INDEX BY SAMTOOLS

process createIndexSamtools {
    tag "GENERATE INDEX BY SAMTOOLS"
    publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false
    
    conda "bioconda::samtools=1.21"
    container "firaszemzem/bwa-samtools:latest"

    input:
        path ref
	    		
    output:
        path "*.fai"	, emit: "samtools_index"
        
    script:
    """
    samtools faidx ${ref}  --output ${ref}.fai                         
    """
}
