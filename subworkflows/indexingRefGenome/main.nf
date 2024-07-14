
String extractPathWithoutFilename(String filePath) {
    def file = new File(filePath)
    def parent = file.parent
    return parent ?: '.'
}

String getBasename(String filePath) {
    return new File(filePath).getName()
} 

process createIndex {
    conda 'bioconda::bwa-mem2=0.7.17'
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER"
    publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false
    input:
       file(reference_genome)
       val(wildcard)
    output: 
       file(wildcard)

    script:
    """
    bwa-mem2 index $reference_genome
    """
}

process createDictionary {
    conda "bioconda::gatk=4.4"
    tag "GENERATE DICTIONARY"
    publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false

    input:
        file(reference_genome)
    
    output:
        file("*.dict")

    """
    gatk CreateSequenceDictionary --REFERENCE $reference_genome
    """
}

process createIndexSamtools {
  conda "bioconda::samtools=1.16.1"
  tag "GENERATE INDEX BY SAMTOOLS"
  publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false

  input: 
    file(reference_genome)
    val(wildcard)

  output:
     file(wildcard)
  
  """
  samtools faidx $reference_genome
  """
}

workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel
    wild_card

  main: 
  
  bwa_index = createIndex(ref_gen_channel, wild_card)
  println("hello")
/*  
  // generate dictionary
  gatk_dic = createDictionary(ref_gen_channel)
  
  // generate samtools index
  wild_card_fai = refgenome_basename+".fai"
  println(wild_card_fai)
  samtools_index = createIndexSamtools(ref_gen_channel, wild_card_fai)

  emit:
    bwa_index, gatk_dic, samtools_index
*/
}
