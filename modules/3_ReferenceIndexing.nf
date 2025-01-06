// Module files for DelMoro pipeline


// 	CREATING INDEX FOR ALINGER
////////////////////////////////////////////////////

process createIndex {
	conda "bioconda::bwa=0.7.18"
	tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA"
        publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false

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
	conda "bioconda::bwa-mem2=2.2.1"
	tag "CREATING INDEX FOR REF GENOME FOR ALIGNER BWA-MEM2"
        publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false

     	input:
     		path ref
     		
   	output:
        	path "*.{0123,amb,ann,bwt.2bit.64,pac}" 	, emit: "bwa_index"
    	script:
        """
        bwa-mem2 index ${ref}               
        """
}



////////////////////////////////////////////////////
//	CREATING DICTIONARY FOR REF GENOME FOR ALIGNER

process createDictionary {
	conda "bioconda::gatk4=4.4"
	tag "GENERATE DICTIONARY"
        publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false

     	input:
     		path ref
     		
   	output:
        	path "*.dict"                           	, emit: "gatk_dic"
    	script:
        """
        gatk CreateSequenceDictionary --REFERENCE ${ref}
        """
}
////////////////////////////////////////////////////
//	CREATING INDEX BY SAMTOOLS

process createIndexSamtools {
	conda "bioconda::samtools=1.21"
	tag "GENERATE INDEX BY SAMTOOLS"
        publishDir "${params.outdir}/Indexes/Reference", mode: 'copy', overwrite: false

     	input:
     		path ref
     		
   	output:
        	path "*.fai"                            	, emit: "samtools_index"
    	script:
        """
        samtools faidx ${ref}  --output ${ref}.fai                         
        """
}
