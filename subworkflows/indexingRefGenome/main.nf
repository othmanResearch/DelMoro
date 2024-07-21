include {createIndex; createDictionary; createIndexSamtools} from '../../modules/' 


workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel
    wild_card
    refgenome_basename 

  main: 
  
  bwa_index = createIndex(ref_gen_channel, wild_card)
  println("hello")

  // generate dictionary
  gatk_dic = createDictionary(ref_gen_channel)

  // generate samtools index
  wild_card_fai = refgenome_basename+".fai"
  samtools_index = createIndexSamtools(ref_gen_channel, wild_card_fai)

/*

  emit:
    bwa_index, gatk_dic, samtools_index
*/
}
