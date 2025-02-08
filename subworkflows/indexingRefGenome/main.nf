// Index Reference subworkflow 

include { DelMoroWelcome  		} from '../../.logos'	
include { DelMoroINXRefenceOutput	} from '../../.logos'		

include { DownloadIgenomes		} from '../../modules/3_ReferenceIndexing' 
include { createIndexBWAMEM2 		} from '../../modules/3_ReferenceIndexing' 	
include { createIndex			} from '../../modules/3_ReferenceIndexing' 
include { createDictionary 		} from '../../modules/3_ReferenceIndexing' 
include { createIndexSamtools		} from '../../modules/3_ReferenceIndexing' 


workflow INDEXING_REF_GENOME {
    take:
	ref_gen_channel

    main: 
if ( !params.igenome &&  params.reference ) { 
    // case1 : Use Default BWA aligner with reference as input 
     if ( !params.aligner ){

	  DelMoroINXRefenceOutput()

	  createIndex		(ref_gen_channel)
	  createDictionary	(ref_gen_channel)
	  createIndexSamtools	(ref_gen_channel)

	  emit:
	  createIndex.out.bwa_index
	  createDictionary.out.gatk_dic
	  createIndexSamtools.out.samtools_index
	      // case2 : Use Default BWA aligner with igenome as input 
	 } else if ( params.aligner == "bwamem2" ){

		     DelMoroINXRefenceOutput()

		     createIndexBWAMEM2	(ref_gen_channel)
	             createDictionary	(ref_gen_channel)
		     createIndexSamtools	(ref_gen_channel)

		     emit:
		     createIndexBWAMEM2.out.bwa_index
		     createDictionary.out.gatk_dic
		     createIndexSamtools.out.samtools_index
		     } else {

			DelMoroWelcome()

			print("\033[31m Please specify valid parameters:\n"			)
		    	print("  --reference option ( --reference <reference-path> ) \n"	) 
		    	print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n"	)
		    	print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
			}
			
    } else if ( params.igenome && !params.reference ){ 
   
  	if (params.IGENOMES && !params.IGENOMES.containsKey(params.igenome)) {
            
            DelMoroWelcome()
    	    exit 1, "The provided genome '${params.igenome}' is not available. Available genomes: ${params.IGENOMES.keySet().join(", ")}"
   	}
   
	    if ( !params.aligner ){
		 		    
		 DelMoroINXRefenceOutput()

	 	 DownloadIgenomes()
		 createIndex		(DownloadIgenomes.out.igenome_ch)
	 	 createDictionary	(DownloadIgenomes.out.igenome_ch)
		 createIndexSamtools	(DownloadIgenomes.out.igenome_ch)

	 	 emit:
	  	 createIndex.out.bwa_index
		 createDictionary.out.gatk_dic
		 createIndexSamtools.out.samtools_index         
		 
		      // case4 : Use Default BWA-MEM2 aligner with igenome as input 
	  	 } else if ( params.aligner == "bwamem2" ){
		 		    
		 	     DelMoroINXRefenceOutput()

			     DownloadIgenomes()
			     createIndexBWAMEM2	(	DownloadIgenomes.out.igenome_ch)
			     createDictionary		(DownloadIgenomes.out.igenome_ch)
			     createIndexSamtools	(DownloadIgenomes.out.igenome_ch)

			     emit:
			     createIndexBWAMEM2.out.bwa_index
			     createDictionary.out.gatk_dic
			     createIndexSamtools.out.samtools_index         
			 
			} else { 
			 	DelMoroWelcome()

				print("\033[31m Please specify valid parameters:\n"			)							
			    	print("  --igenome option (e.g, --igenome EB1 ) \n"	)
			    	print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n"	)
			    	print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
			}
	} else {
	    DelMoroWelcome()

	    print("\033[31m Please specify valid parameters:\n"			)
	    print("  --reference option ( --reference <reference-path> ) \n"	)
 	    print("  or  \n"	)
	    print("  --igenome option (e.g, --igenome EB1 ) \n"	)
	    print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n"	)
	    print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
	}
}

  
