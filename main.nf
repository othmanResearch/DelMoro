#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
def prinLoGO()	{   

log.info"""                                                                                                                                                                                                                                                         

\033[37m  DDDDDDDDDDDDD                           \033[37mLLLLLLLLLLL             \033[31mMMMMMMMM               MMMMMMMM                                                      
\033[37m  D::::::::::::DDD                        \033[37mL:::::::::L             \033[31mM:::::::M             M:::::::M                                                      
\033[37m  D:::::::::::::::DD                      \033[37mL:::::::::L             \033[31mM::::::::M           M::::::::M                                                      
\033[37m  DDD:::::DDDDD:::::D                     \033[37mLL:::::::LL             \033[31mM:::::::::M         M:::::::::M                                                      
\033[37m   D:::::D    D:::::D    eeeeeeeeeeee     \033[37mL:::::L                 \033[31mM::::::::::M       M::::::::::M\033[37m   ooooooooooo   rrrrr   rrrrrrrrr      ooooooooooo   
\033[37m   D:::::D     D:::::D  ee::::::::::::ee  \033[37mL:::::L                 \033[31mM:::::::::::M     M:::::::::::M\033[37m oo:::::::::::oo r::::rrr:::::::::r   oo:::::::::::oo 
\033[37m   D:::::D     D:::::D e::::::eeeee:::::ee\033[37mL:::::L                 \033[31mM:::::::M::::M   M::::M:::::::M\033[37mo:::::::::::::::or:::::::::::::::::r o:::::::::::::::o
\033[37m   D:::::D     D:::::De::::::e     e:::::e\033[37mL:::::L                 \033[31mM::::::M M::::M M::::M M::::::M\033[37mo:::::ooooo:::::orr::::::rrrrr::::::ro:::::ooooo:::::o
\033[37m   D:::::D     D:::::De:::::::eeeee::::::e\033[37mL:::::L                 \033[31mM::::::M  M::::M::::M  M::::::M\033[37mo::::o     o::::o r:::::r     r:::::ro::::o     o::::o
\033[37m   D:::::D     D:::::De:::::::::::::::::e \033[37mL:::::L                 \033[31mM::::::M   M:::::::M   M::::::M\033[37mo::::o     o::::o r:::::r     rrrrrrro::::o     o::::o
\033[37m   D:::::D     D:::::De::::::eeeeeeeeeee  \033[37mL:::::L                 \033[31mM::::::M    M:::::M    M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m   D:::::D    D:::::D e:::::::e           \033[37mL:::::L         LLLLLLLL\033[31mM::::::M     MMMMM     M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m DDD:::::DDDDD:::::D  e::::::::e          \033[37mLL:::::::LLLLLLLLL:::::L\033[31mM::::::M               M::::::M\033[37mo:::::ooooo:::::o r:::::r            o:::::ooooo:::::o
\033[37m D:::::::::::::::DD    e::::::::eeeeeeee  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37mo:::::::::::::::o r:::::r            o:::::::::::::::o
\033[37m D::::::::::::DDD       ee:::::::::::::e  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37m oo:::::::::::oo  r:::::r             oo:::::::::::oo 
\033[37m DDDDDDDDDDDDD            eeeeeeeeeeeeee  \033[37mLLLLLLLLLLLLLLLLLLLLLLLL\033[31mMMMMMMMM               MMMMMMMM\033[37m   ooooooooooo    rrrrrrr               ooooooooooo   

                                                                    
\033[37m                                                                        \033[31m X
\033[37m         o O        o O       o O       o o       o O        o O o       o                    o O       o       o O       o O      o O       o O    
\033[37m       o | | O    o | | O   o | | O   o | |O     o| | O    o | | | O      o                 o | | O   o | O   o | | O    o| | O  o | | O   o | | O
\033[37m O | | | | | | | O  | | | | O | | | | O | | o | O | | | | O  | | | | o O O O O O O O O O O O || | | | O | | | O | | | | O | | | |  | | | | | | | | | | O 
\033[37m       o | | o    O | | o   O | | o   O | o      O| | o    O | | | o          o             O | | o   O | o   O | | o   O | | o  O | | o   O | | o 
\033[37m         o o        O o       O o       O         O o        O o o             o              O o       O       O o       O o      O o       O o     
                                                                                \033[31m o o X\033[37m

\033[32m
Usage  :\033[37m nextflow main.nf --exec [Step..] [Params..]
\033[32m
Steps :\033[37m   - ControlRawQuality : Checks quality of raw reads. 
	  - Trimm : Removes low-quality bases and adapters and checks it quality.
	  - IndexRef : Indexes the reference genome for alignment.
	  - KnSIndex : Indexes knowns sites vcf for base recalibration.
	  - Align : Aligns reads to the reference genome.
	  - CallSNP : Detects SNPs from aligned reads.
	  - ShowParams : See Default params.
	  - Version  
	   
"""		}


//  params To be printed 
def printparmas() {
log.info"""
\033[32m params.refGenome 	=\033[37m ./Reference_Genome/reference.fa	       // Reference file path

\033[32m params.RawReads 	=\033[37m ./CSVs/1_samplesheetForRawQC.csv 		 // Raw reads paths 
\033[32m params.ToBeTrimmed 	=\033[37m ./CSVs/2_SamplesheetForTrimming.csv		   // Raw reads paths + trimmomatic parameters
\033[32m params.TrimmedReads 	=\033[37m ./CSVs/3_samplesheetForAssembly.csv		     // Trimmed read paths 
\033[32m params.BamFiles	=\033[37m ./CSVs/4_samplesheetForBamFiles.csv  	               // Bam files paths 

\033[32m params.knwonSite1	=\033[37m ./knownsites/1000g_gold_standard.indels.filtered.vcf 	// knownsites should be .vcf  
\033[32m params.knwonSite2 	=\033[37m ./knownsites/GCF.38.filtered.renamed.vcf			

\033[32m params.BamIndex	=\033[37m ./outdir/Indexes/BamFiles/*.bai				     // Bam Files Indexes

\033[32m params.ALIGNERIndex	=\033[37m ./outdir/Indexes/Reference/reference.fa.{0123,amb,ann,bwt.2bit.64,pac}  // Bwa-mem2 		Reference Indexes
\033[32m params.Dictionary	=\033[37m ./outdir/Indexes/Reference/reference.dict				    // GATK Dictionary 	Reference Index
\033[32m params.SamtoolsIndex	=\033[37m ./outdir/Indexes/Reference/reference.fa.fai  			              // Samtools fai 		Reference Index

\033[32m params.KnSite1Idx 	=\033[37m ./outdir/Indexes/knownSites/1000g_gold_standard.indels.filtered.vcf.idx    // Known site 1 Index
\033[32m params.KnSite2Idx 	=\033[37m ./outdir/Indexes/knownSites/GCF.38.filtered.renamed.vcf.idx		   //  Known site 2 Index

\033[32m params.cpus 		=\033[37m 2
\033[32m params.outdir		=\033[37m ./outdir  \033[32m
"""}



// Params 

params.refGenome 	= "./Reference_Genome/reference.fa"		// Reference file path

params.RawReads 	= "./CSVs/1_samplesheetForRawQC.csv" 		// Raw reads paths 
params.ToBeTrimmed 	= "./CSVs/2_SamplesheetForTrimming.csv"		// Raw reads paths + trimmomatic parameters
params.TrimmedReads 	= "./CSVs/3_samplesheetForAssembly.csv"		// Trimmed read paths 
params.BamFiles		= "./CSVs/4_samplesheetForBamFiles.csv"  			// Bam files paths 

params.knwonSite1	= "./knownsites/1000g_gold_standard.indels.filtered.vcf" 	// knownsites should be .vcf  
params.knwonSite2 	= "./knownsites/GCF.38.filtered.renamed.vcf"			

// Indexes params 

params.BamIndex		= "./outdir/Indexes/BamFiles/*.bai"					   	  // Bam Files Indexes

params.ALIGNERIndex	= "./outdir/Indexes/Reference/reference.fa.{0123,amb,ann,bwt.2bit.64,pac}"         // Bwa-mem2 		Reference Indexes
params.Dictionary	= "./outdir/Indexes/Reference/reference.dict"				       // GATK Dictionary 	Reference Index
params.SamtoolsIndex	= "./outdir/Indexes/Reference/reference.fa.fai"  			              // Samtools fai 		Reference Index

params.KnSite1Idx 	= "./outdir/Indexes/knownSites/1000g_gold_standard.indels.filtered.vcf.idx"    // Known site 1 Index
params.KnSite2Idx 	= "./outdir/Indexes/knownSites/GCF.38.filtered.renamed.vcf.idx"		   //  Known site 2 Index

params.cpus 		= 2
params.outdir		= "./outdir"

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
  params.exec = ''  // Default to 'none' if not provided
  
if (params.exec =='' ){
	
   prinLoGO()   
  
  } else if (params.exec == 'ControlRawQuality') {	// check quality of raw reads
 
      QC_RAW_READS(RawREADS)  
	
      } else if (params.exec == 'Trimm') {		// trim reads

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
  	        
  	         printparmas()
  	       
  	        } else if ( params.exec == 'Version' ) {
	          prinLoGO()
log.info """
\033[31m DelMoro version :\033[37m v1.00 
"""   
  	   } else {
  	     prinLoGO()
log.info """
\033[31m ⚠︎  Please Verify The Typed Params \033[37m 
"""   }
  	      
 }






