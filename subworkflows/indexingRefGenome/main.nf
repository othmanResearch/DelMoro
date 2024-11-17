// Index Reference subworkflow 

include {DelMoroWelcome; DelMoroINXRefenceOutput} from '../../logos'		
include {createIndex; createDictionary; createIndexSamtools} from '../../modules/3_ReferenceIndexing' 

workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel

  main: 
  if (params.exec != null && params.reference != null ) {
     DelMoroINXRefenceOutput()
     createIndex(ref_gen_channel)
     createDictionary(ref_gen_channel)
     createIndexSamtools(ref_gen_channel)
     
    emit:
    createIndex.out.bwa_index
    createDictionary.out.gatk_dic
    createIndexSamtools.out.samtools_index
	} else { 
	    DelMoroWelcome() 
	    print("\033[31m Please specify valid parameters:\n")
    	    print("  --reference option ( --reference <reference-path> ) \n")
    	    print("For details, run: nextflow main.nf --exec params\n\033[37m")
			 
	    }
       





}
 
