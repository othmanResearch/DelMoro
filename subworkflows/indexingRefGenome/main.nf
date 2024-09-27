// Index Reference subworkflow 

include {DelMoroINXRefenceOutput} from '../../logos'		
include {createIndex; createDictionary; createIndexSamtools} from '../../modules/3_ReferenceIndexing' 

workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel

  main: 
  DelMoroINXRefenceOutput()
  createIndex(ref_gen_channel)
  createDictionary(ref_gen_channel)
  createIndexSamtools(ref_gen_channel)



  emit:
    createIndex.out.bwa_index
    createDictionary.out.gatk_dic
    createIndexSamtools.out.samtools_index


}
