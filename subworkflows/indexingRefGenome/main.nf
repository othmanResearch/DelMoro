// Index Reference subworkflow 

include { DelMoroWelcome 	  } from '../../.logos'    
include { DelMoroINXRefenceOutput } from '../../.logos'    

include { DownloadIgenomes 	  } from '../../modules/03.0_ReferenceIndexing.nf' 
include { CreateIndexBwaMem2 	  } from '../../modules/03.0_ReferenceIndexing.nf'     
include { CreateIndex  	   	  } from '../../modules/03.0_ReferenceIndexing.nf' 
include { CreateDictionary 	  } from '../../modules/03.0_ReferenceIndexing.nf' 
include { CreateIndexSamtools  	  } from '../../modules/03.0_ReferenceIndexing.nf' 

workflow INDEXING_REF_GENOME {
    take:
    ref_gen_channel

    main: 
    if (params.stepmode && params.exec == "refidx") { DelMoroINXRefenceOutput() }

    if (!params.igenome && params.reference) { 
        // Case 1: Use Default BWA aligner with reference as input 
        if (!params.aligner) {
            CreateIndex(ref_gen_channel)
            CreateDictionary(ref_gen_channel)
            CreateIndexSamtools(ref_gen_channel)

            emit:
            reference_fasta = ref_gen_channel
            bwaIndex = CreateIndex.out.bwaIndex
            gatkDict = CreateDictionary.out.gatkDict
            samtoolsIndex = CreateIndexSamtools.out.samtoolsIndex
            combinedIdx = bwaIndex.combine(gatkDict).combine(samtoolsIndex)
         
        // Case 2: Use BWA-MEM2 aligner with reference as input
        } else if (params.aligner == "bwamem2") {
            CreateIndexBwaMem2(ref_gen_channel)
            CreateDictionary(ref_gen_channel)
            CreateIndexSamtools(ref_gen_channel)

            emit:
            reference_fasta = ref_gen_channel
            bwa2Index = CreateIndexBwaMem2.out.bwaIndex
            gatkDict = CreateDictionary.out.gatkDict
            samtoolsIndex = CreateIndexSamtools.out.samtoolsIndex
            combinedIdx = bwa2Index.combine(gatkDict).combine(samtoolsIndex)
            
        } else {
            DelMoroWelcome()
            error("\033[31m Please specify valid parameters:\n\n" +
                  "  --reference option (--reference <reference-path>)\n\n" + 
                  "  --aligner bwamem2, Default bwa (not to be mentioned)\n\n" +
                  " For details, run: nextflow main.nf --exec params\n\033[37m")
        }
    } else if (params.igenome && !params.reference) { 
        if (params.IGENOMES && !params.IGENOMES.containsKey(params.igenome)) {
            DelMoroWelcome()
            exit 1, "The provided genome '${params.igenome}' is not available. Available genomes: ${params.IGENOMES.keySet().join(", ")}"
        }
        
        // Case 3: Use Default BWA aligner with igenome as input
        if (!params.aligner) {
            DownloadIgenomes()
            CreateIndex(DownloadIgenomes.out.igenome_ch)
            CreateDictionary(DownloadIgenomes.out.igenome_ch)
            CreateIndexSamtools(DownloadIgenomes.out.igenome_ch)

            emit:
            reference_fasta = DownloadIgenomes.out.igenome_ch
            bwaIndex = CreateIndex.out.bwaIndex
            gatkDict = CreateDictionary.out.gatkDict
            samtoolsIndex = CreateIndexSamtools.out.samtoolsIndex
            combinedIdx = bwaIndex.combine(gatkDict).combine(samtoolsIndex)

        // Case 4: Use BWA-MEM2 aligner with igenome as input
        } else if (params.aligner == "bwamem2") {
            DownloadIgenomes()
            CreateIndexBwaMem2(DownloadIgenomes.out.igenome_ch)
            CreateDictionary(DownloadIgenomes.out.igenome_ch)
            CreateIndexSamtools(DownloadIgenomes.out.igenome_ch)

            emit:
            reference_fasta = DownloadIgenomes.out.igenome_ch
            bwa2Index = CreateIndexBwaMem2.out.bwaIndex
            gatkDict = CreateDictionary.out.gatkDict
            samtoolsIndex = CreateIndexSamtools.out.samtoolsIndex
            combinedIdx = bwa2Index.combine(gatkDict).combine(samtoolsIndex)
            
        } else { 
            DelMoroWelcome()
            error("\033[31m Please specify valid parameters:\n\n" +               
                  "  --igenome option (e.g., --igenome EB1)\n\n" +
                  "  --aligner bwamem2, Default bwa (not to be mentioned)\n\n" +
                  " For details, run: nextflow main.nf --exec params\n\n\033[37m")
        }
    } else {
	error("\033[31m Error: Invalid or missing parameters.\n\n"              +
              " Please specify valid parameters:\n\n"                   +
              "  --reference option (--reference <reference-path>)\n\n"         +
              "  or\n\n"                                                        +
              "  --igenome option (e.g., --igenome EB1)\n\n"                    +
              "  --aligner bwamem2, Default bwa (not to be mentioned)\n\n"      +
              " ----------------------------------------------------\n\n"       +
	      " For more information:\n\n"                                      +
              "   >>  View the help menu: nextflow main.nf --help\n\n"	      +
	      "   >>  Check parameters: nextflow main.nf --params\n\n \033[37m"  )
    }
    
    emit:
    reference_fasta = params.igenome ? DownloadIgenomes.out.igenome_ch : ref_gen_channel
    alignerIdx = (params.aligner == "bwamem2") ? bwa2Index : bwaIndex
    gatkDict = CreateDictionary.out.gatkDict
    samtoolsIndex = CreateIndexSamtools.out.samtoolsIndex
    combinedIdx = alignerIdx.combine(gatkDict).combine(samtoolsIndex)
}


