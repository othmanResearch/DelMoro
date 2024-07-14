#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include {INDEXING_REF_GENOME} from './subworkflows/indexingRefGenome'

String extractPathWithoutFilename(String filePath) {
    def file = new File(filePath)
    def parent = file.parent
    return parent ?: '.'
}

String getBasename(String filePath) {
    return new File(filePath).getName()
} 


workflow {
  params.exec = params.exec ?: 'none'  // Default to 'none' if not provided


  if ( params.exec == 'none')
  {
    log.info """
    =====
    DelMoro workflow
    =====

    """
  } else if (params.exec == 'qc')
  {
    params.refGenome = "../../FHG_clinical_bioinformatics/assembly_ngs/ref_genome/chr21.fa"
  // generate index for reference genome
  params.referenceGenomeRoot = extractPathWithoutFilename(params.refGenome)  // get root
  println(params.referenceGenomeRoot)
  refgenome_basename = getBasename(params.refGenome)  
  wild_card = refgenome_basename+".*"
  ref_gen_channel = Channel.fromPath(params.refGenome)
 
  INDEXING_REF_GENOME(ref_gen_channel, wild_card)
  }





}

