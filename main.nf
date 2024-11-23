#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// params 

// Interactive Design while Running DelMoro

include {DelMoroWelcome	}	from './logos' 
include {DelMoroParams	}	from './logos' 
include {DelMoroVersion	} 	from './logos' 
include {DelMoroHelp	} 	from './logos' 
include {DelMoroError	} 	from './logos' 

	       			             	 	
// channels 
  // prepare required csv from an intial csv
  preparecsv 		= params.basedon	? Channel.fromPath(params.basedon, checkIfExists: true)   			: Channel.empty()   	
 
  // Raw Reads to quality check 
  RawREADS 		= params.rawreads 	? Channel.fromPath(params.rawreads, checkIfExists: true)       	
	       			             	 	  .splitCsv(header: true)  
       	       	                     		           .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) }	: Channel.empty() 
       	       
  // Raw Reads to be trimmed based on required features  : MINLEN , LEADING, TRAILING, SLIDINGWINDOW
       	
  ReadsToBeTrimmed	= params.tobetrimmed 	? Channel.fromPath(params.tobetrimmed, checkIfExists: false)       	
	       						  .splitCsv(header: true)  
	       						   .map { row -> tuple(row.patient_id,
       		      					    file(row.R1), 
       		      				   	     file(row.R2), 
       		      				              row.MINLEN, 	
       		         				       row.LEADING,
       		         			 	        row.TRAILING, 
       		           				         row.SLIDINGWINDOW ) } 						: Channel.empty()
  // Trimmed reads      	       
  ReadsToBeAligned	= params.tobealigned  	? Channel.fromPath(params.tobealigned, checkIfExists: false)       	
	       					 	  .splitCsv(header: true)  
       	      				          	   .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) }	: Channel.empty() 

       	       
  // reference

  ref_gen_channel	= params.reference	? Channel.fromPath(params.reference).first()					: Channel.empty()
       
  // BamFiles channel

  MappedReads 		= params.bam	? Channel.fromPath(params.bam, checkIfExists: false)  
       	       						 .splitCsv(header: true)  
            						 .map{ row -> tuple(row.patient_id, file(row.BamFile))}			: Channel.empty() 
            						
  // target bed file to extract coverage 
  Target		= params.bedtarget	? Channel.fromPath(params.bedtarget, checkIfExists: false).first()		: Channel.empty()      
	
  // knwon file 1 channel for BQSR    

  knownSite1		= params.knownSite1	? Channel.fromPath(params.knownSite1, checkIfExists: false).first()   		: Channel.empty() 
       
  // knwon file 2 channel for BQSR       
         
  knownSite2		= params.knownSite2	? Channel.fromPath(params.knownSite2, checkIfExists: false).first()  		: Channel.empty() 

  // Indexes Channels 

	// Aligner Indexs Bwa mem2 
	Channel.fromPath(params.ALIGNERIndex, checkIfExists: false)  
       		.set{ALignidxREF}
       	
       	//  Dictionary Indexs Bwa mem2 
	Channel.fromPath(params.DictGATK, checkIfExists: false)  
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


// subworkflows *
include {GenerateCSVs} 		from './subworkflows/GenerateCSV'
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
  GenerateCSVs(preparecsv)
  
  } else if (params.exec == 'rawqc') {	// check quality of raw reads
 
      QC_RAW_READS(RawREADS)  
	
      } else if (params.exec == 'trim') {		// trim reads

        TRIM_READS(ReadsToBeTrimmed)  
	
   	} else if (params.exec == 'refidx') { 	// generate index for reference genome	

      	  INDEXING_REF_GENOME(ref_gen_channel) 
	
   	  } else if (params.exec == 'knsidx') { 	// generate index for known sites files

      	    INDEXING_known_sites(knownSite1,knownSite2)  
	
   	    } else if (params.exec == 'align') {	// align reads to reference

  	      ALIGN_TO_REF_GENOME(ref_gen_channel,ALignidxREF,ReadsToBeAligned,Target) 
  	
  	      } else if (params.exec == 'callsnp') {	// Call snp

  	        Call_SNPs_with_GATK(ref_gen_channel,DictidxREF,SamtidxREF,MappedReads, IDXBAM,knownSite1, IDXknS1,knownSite2, IDXknS2 ) 
  	     
  	      } else if ( params.exec == 'help'){
  	        
  	         DelMoroHelp()
  	       
  	        } else if ( params.exec == 'params' ) {
	          
	          DelMoroParams()
	         
	          } else if ( params.exec == 'version' ) {
	          
	            DelMoroVersion()

  	  	    } else { DelMoroError() }
  	      
 }






