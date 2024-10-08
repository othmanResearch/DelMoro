// Index Reference subworkflow 

include {DelMoroWelcome; DelMoroINXRefenceOutput} from '../../logos'		
include {createIndex; createDictionary; createIndexSamtools} from '../../modules/3_ReferenceIndexing' 

workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel

  main: 
  if (params.exec != null && params.refGenome != null ) {
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
	    print("\033[31m please specify --refGenome option (--refGenome reference ) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
       





}
 
