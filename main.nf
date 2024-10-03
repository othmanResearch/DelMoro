#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


// channels 

   // Raw Reads to quality check 
	
	Channel.fromPath(params.RawReads, checkIfExists: true)       	
	       .splitCsv(header: true)  
       	       .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) } 
       	       .set{ RawREADS }
       	       
  // Raw Reads to be trimmed based on required features  : MINLEN , LEADING, TRAILING, SLIDINGWINDOW
       	
       	Channel.fromPath(params.ToBeTrimmed, checkIfExists: true)       	
	       .splitCsv(header: true)  
	       .map { row -> tuple(row.patient_id,
       		      file(row.R1), 
       		       file(row.R2), 
       		        row.MINLEN, 
       		         row.LEADING,
       		          row.TRAILING, 
       		           row.SLIDINGWINDOW ) 	}.set{ ReadsToBeTrimmed }
  // Trimmed reads      	       
       	 Channel.fromPath(params.TrimmedReads, checkIfExists: false)       	
	       .splitCsv(header: true)  
       	       .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) } 
       	       .set{ TrimmedREADS }	
  

       	       
  // reference

	Channel.fromPath(params.refGenome)
	       .first()
	       .set{ ref_gen_channel }
       
  // BamFiles channel

	Channel.fromPath(params.BamFiles, checkIfExists: false)  
       	       .splitCsv(header: true)  
               .map{ row -> tuple(row.patient_id, file(row.BamFile))}
               .set { MappedReads }

  // knwon file 1 channel for BQSR    

	Channel.fromPath(params.knwonSite1, checkIfExists: false)  
               .first()
               .set{knwonSite1}    
       
  // knwon file 2 channel for BQSR       
         
	Channel.fromPath(params.knwonSite2, checkIfExists: false)  
               .first()
               .set{knwonSite2}    
       
  // Indexes Channels 

	// Aligner Indexs Bwa mem2 
	Channel.fromPath(params.ALIGNERIndex, checkIfExists: false)  
       		.set{ALignidxREF}
       	
       	//  Dictionary Indexs Bwa mem2 
	Channel.fromPath(params.Dictionary, checkIfExists: false)  
       		.set{DictidxREF}
       	
       	// SamtoolsIndex
       	Channel.fromPath(params.SamtoolsIndex, checkIfExists: false)  
       		.set{SamtidxREF}
       		
       	// Bam Files Index
       	Channel.fromPath(params.BamIndex, checkIfExists: false)  
       		.set{IDXBAM}

       	// knwon Site1 index 
    	Channel.fromPath(params.KnSite1Idx, checkIfExists: false)  
    		.first()
       		.set{IDXknS1}
     	
     	// knwon Site2 index 
    	Channel.fromPath(params.KnSite2Idx, checkIfExists: false)  
    		.first()
       		.set{IDXknS2}	


// subworkflows 
include {QC_RAW_READS} 		from './subworkflows/RawQualCtrl'
include {TRIM_READS} 		from './subworkflows/Trimming'
include {INDEXING_REF_GENOME} 	from './subworkflows/indexingRefGenome'
include {INDEXING_known_sites} 	from './subworkflows/IndexingKnownSites'
include {ALIGN_TO_REF_GENOME} 	from './subworkflows/Assembly'
include {Call_SNPs_with_GATK} 	from './subworkflows/variantcalling'


workflow {
  params.exec = null  // Default to 'none' if not provided
  
if (params.exec == null ){
	
  DelMoroWelcome()   
  
  } else if (params.exec == 'ControlRawQuality') {	// check quality of raw reads
 
      QC_RAW_READS(RawREADS)  
	
      } else if (params.exec == 'Trim') {		// trim reads

        TRIM_READS(ReadsToBeTrimmed)  
	
   	} else if (params.exec == 'IndexRef') { 	// generate index for reference genome	

      	  INDEXING_REF_GENOME(ref_gen_channel) 
	
   	  } else if (params.exec == 'KnSIndex') { 	// generate index for known sites files

      	    INDEXING_known_sites(knwonSite1,knwonSite2)  
	
   	    } else if (params.exec == 'Align') {	// align reads to reference

  	      ALIGN_TO_REF_GENOME(ref_gen_channel,ALignidxREF,TrimmedREADS) 
  	
  	      } else if (params.exec == 'CallSNP') {	// Call snp

  	        Call_SNPs_with_GATK(ref_gen_channel,DictidxREF,SamtidxREF,MappedReads, IDXBAM,knwonSite1, IDXknS1,knwonSite2, IDXknS2 ) 
  	     
  	      } else if ( params.exec == 'ShowParams'){
  	        
  	         DelMoroParams()
  	       
  	        } else if ( params.exec == 'Version' ) {
	          
	          DelMoroVersion()

  	  	   } else { DelMoroError() }
  	      
 }






