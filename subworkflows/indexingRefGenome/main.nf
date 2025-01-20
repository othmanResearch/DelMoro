// Index Reference subworkflow 

include { DelMoroWelcome  		} from '../../logos'	
include { DelMoroINXRefenceOutput	} from '../../logos'		
	
include { createIndex			} from '../../modules/3_ReferenceIndexing' 
include { createIndexBWAMEM2 		} from '../../modules/3_ReferenceIndexing' 
include { createDictionary 		} from '../../modules/3_ReferenceIndexing' 
include { createIndexSamtools		} from '../../modules/3_ReferenceIndexing' 
 

workflow INDEXING_REF_GENOME {
   take:
      ref_gen_channel

   main:
     if ( params.exec 		!= null &&
   	  params.reference 	!= null &&
          params.aligner 	== null ){

	  DelMoroINXRefenceOutput()

	  createIndex		(ref_gen_channel)
	  createDictionary	(ref_gen_channel)
	  createIndexSamtools	(ref_gen_channel)

	  emit:
	  createIndex.out.bwa_index
	  createDictionary.out.gatk_dic
	  createIndexSamtools.out.samtools_index

       } else if ( params.exec		!= null &&
		   params.reference 	!= null &&
		   params.aligner	== "bwamem2"){

		   DelMoroINXRefenceOutput()

		   createIndexBWAMEM2	(ref_gen_channel)
	           createDictionary	(ref_gen_channel)
		   createIndexSamtools	(ref_gen_channel)

		   emit:
		   createIndexBWAMEM2.out.bwa_index
		   createDictionary.out.gatk_dic
		   createIndexSamtools.out.samtools_index

		} else if ( params.aligner != "bwamem2"	){

			DelMoroWelcome()

			print("\033[31m Please specify valid parameters:\n"			)
			print("  --reference option ( --reference <reference-path> ) \n"	)
			print("  -aligner bwamem2 , Default bwa ( not to be mentionned ) \n"	)
			print("For details, run: nextflow main.nf --exec params\n\033[37m"	)

	 } 
}
 

