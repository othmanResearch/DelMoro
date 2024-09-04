// Module files for DelMoro pipeline


// 	CREATING INDEX FOR ALINGER
////////////////////////////////////////////////////

process createIndex {
	conda "bioconda::gatk4=4.4 bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.19"
	tag "CREATING INDEX FOR REF GENOME FOR ALIGNER"
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
	conda "bioconda::gatk4=4.4 bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.19"
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
	conda "bioconda::gatk4=4.4 bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.19"
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




