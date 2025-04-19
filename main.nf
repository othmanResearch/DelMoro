#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// params 

// Interactive Design while Running DelMoro

include {DelMoroWelcome	}	from './.logos' 
include {DelMoroParams	}	from './.logos' 
include {DelMoroVersion	} 	from './.logos' 
include {DelMoroHelp	} 	from './.logos' 
include {DelMoroError	} 	from './.logos' 
include {DelMoroAnnotateHelp	} 	from './.logos' 
	       			             	 	
// channels 
  // prepare required csv from an intial csv
  PrepareCsv 		= params.basedon	? Channel.fromPath(params.basedon, checkIfExists: true)   			: Channel.empty()   	
 
  // Raw Reads to quality check 
  RawReads 		= params.rawreads 	? Channel.fromPath(params.rawreads, checkIfExists: true)       	
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

  RefGenChannel		= params.reference	? Channel.fromPath(params.reference).first()					: Channel.empty()
  
  // BamFiles channel
    // used for base recalibration
    MappedReads 	= params.bam 		? Channel.fromPath(params.bam, checkIfExists: false)
                                   			  .splitCsv(header: true)
                                    		  	   .map { row -> tuple(row.patient_id, file(row.BamFile)) }
                               	     		  	    .toSortedList { a, b -> a[0] <=> b[0] }   	 
                                      		   	     .flatMap { it } 							: Channel.empty()
    // used for variant calling
    ToVarCall		= params.tovarcall      ? Channel.fromPath(params.tovarcall, checkIfExists: false)
                                   			  .splitCsv(header: true)
                                    		  	   .map { row -> tuple(row.patient_id, file(row.BamFile)) }
                               	     		  	    .toSortedList { a, b -> a[0] <=> b[0] }   	 
                                      		   	     .flatMap { it } 							: Channel.empty()
    						
  // target bed file to extract coverage 
  Target		= params.bedtarget	? Channel.fromPath(params.bedtarget, checkIfExists: false).first()		: Channel.empty()      
	
  // knwon file 1 channel for BQSR    

  KnownSite1		= params.knownsite1	? Channel.fromPath(params.knownsite1, checkIfExists: false).first()   		: Channel.empty() 
       			         
  // knwon file 2 channel for BQSR       
         
  KnownSite2		= params.knownsite2	? Channel.fromPath(params.knownsite2, checkIfExists: false).first()  		: Channel.empty() 

  // Indexes Channels 

    // Aligner Indexs Bwa mem2 
    AlignIdxRef		= params.alignerindex 	? Channel.fromPath(params.alignerindex, checkIfExists: false)  			: Channel.empty()
       	
    //  Dictionary Indexs Bwa mem2 
    DictIdxRef		= params.dictgatk	? Channel.fromPath(params.dictgatk, checkIfExists: false)  			: Channel.empty()
       	
    // SamtoolsIndex
    SamtIdxRef    	= params.samtoolsindex 	? Channel.fromPath(params.samtoolsindex, checkIfExists: false)  		: Channel.empty()
       		
    // Bam Files Index
    IdxBam     		= params.bamindex	? Channel.fromPath(params.bamindex, checkIfExists: false)  			: Channel.empty()
  
  // Vep Annotations Params 
    
 
    VepSpecies		= params.species	?: ''     	 
    Assembly		= params.assembly 	?: ''	 
    CacheType 		= params.cachetype  	?: ''

    CacheDir 		= params.cachedir	?: './vep_cache'	 	 

       

// subworkflows 
include { GENERATE_CSVS		} from './subworkflows/GenerateCSV'
include { QC_RAW_READS		} from './subworkflows/RawQualCtrl'
include { TRIM_READS		} from './subworkflows/Trimming'
include { INDEXING_REF_GENOME	} from './subworkflows/indexingRefGenome'
include { ALIGN_TO_REF_GENOME	} from './subworkflows/Assembly'
include { BASE_QU_SCO_RECA 	} from './subworkflows/BQSR'
include { CALL_SNPs_GATK	} from './subworkflows/variantcalling'
include { VEP_CACHE		} from './subworkflows/annotations/vep/vepcache'

workflow {
  params.exec = null  // Default to 'none' if not provided
  
if (params.exec == null ){
	
  DelMoroWelcome()   
  GENERATE_CSVS(PrepareCsv)
  
  } else if (params.exec == 'rawqc') {	// check quality of raw reads
 
      QC_RAW_READS(RawReads)  
	
      } else if (params.exec == 'trim') {		// trim reads

        TRIM_READS(ReadsToBeTrimmed)  
	
   	} else if (params.exec == 'refidx') { 	// generate index for reference genome	

      	  INDEXING_REF_GENOME(RefGenChannel) 
 
   	  } else if (params.exec == 'align') {	// align reads to reference

  	    ALIGN_TO_REF_GENOME(RefGenChannel,AlignIdxRef,ReadsToBeAligned,Target) 
  	
  	    } else if (params.exec == 'bqsr') {
  	      
  	      BASE_QU_SCO_RECA(RefGenChannel,DictIdxRef,SamtIdxRef,MappedReads,IdxBam,KnownSite1,KnownSite2 )
  	          
  	      } else if (params.exec == 'callsnp') {	// Call snp
              
     	        CALL_SNPs_GATK(RefGenChannel,DictIdxRef,SamtIdxRef,ToVarCall,IdxBam) 
  	     
  	        } else if ( params.exec == 'annotate' ) {
  	         // VEP_CACHE(VepSpecies,CacheDir )
  	          DelMoroAnnotateHelp()
  	          
  	          } else if ( params.exec == 'vepcache' ) {
  	         
  	            VEP_CACHE(VepSpecies,Assembly,CacheType,CacheDir)
  	          
  	            } else if ( params.exec == 'help'){
  	        
  	              DelMoroHelp()
  	       
  	              } else if ( params.exec == 'params' ) {
	                
	                DelMoroParams()
	         
	                } else if ( params.exec == 'version' ) {
	           
	                  DelMoroVersion()

  	  	          } else { DelMoroError() }
   
 }
 
 
 
 /*
 workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    file("./work").deleteDir()
}
*/





