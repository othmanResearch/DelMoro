// Module files for DelMoro pipeline

process createIndex {
    tag "CREATING INDEX FOR REF GENOME FOR ALIGNER"
    //publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false
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

////////////////////////////////////////////////////
process createDictionary {
    tag "GENERATE DICTIONARY"
    //publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false

    input:
        file(reference_genome)
    
    output:
        file("*.dict")

    """
    gatk CreateSequenceDictionary --REFERENCE $reference_genome
    """
}

////////////////////////////////////////////////////
process createIndexSamtools {
  tag "GENERATE INDEX BY SAMTOOLS"
  //publishDir params.referenceGenomeRoot, mode: 'copy', overwrite: false

  input: 
    file(reference_genome)
    val(wildcard)

  output:
     file(wildcard)

  
  """
  samtools faidx $reference_genome
  """
}