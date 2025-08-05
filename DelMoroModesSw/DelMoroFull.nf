#!/usr/bin/env nextflow

include { FullModeOutput 	} from '../.logos' 
include { FullModeBqsrOutput 	} from '../.logos'  

// Subworkflows
include { INDEXING_REF_GENOME 	} from '../subworkflows/indexingRefGenome'
include { ALIGN_TO_REF_GENOME 	} from '../subworkflows/mapping'
include { BASE_QU_SCO_RECA 	} from '../subworkflows/bqsr'
include { CALL_SNPs_GATK 	} from '../subworkflows/variantcalling'


workflow DelMoroFullSw {
    take: 
    RefGenChannel
    ReadsToBeAligned
    Target
    KnownSite1
    KnownSite2
    
    main: 
        
    if (params.bqsr) {
        FullModeBqsrOutput()
	INDEXING_REF_GENOME(RefGenChannel)

        ALIGN_TO_REF_GENOME(
            INDEXING_REF_GENOME.out.reference_fasta,
            INDEXING_REF_GENOME.out.combinedIdx.collect(),
            ReadsToBeAligned,
            Target
        ) 
        
        BASE_QU_SCO_RECA(
            INDEXING_REF_GENOME.out.reference_fasta,
            INDEXING_REF_GENOME.out.gatkDict,
            INDEXING_REF_GENOME.out.samtoolsIndex,
            ALIGN_TO_REF_GENOME.out.bams,
            ALIGN_TO_REF_GENOME.out.bamIdx,
            KnownSite1,
            KnownSite2
        )
        
        CALL_SNPs_GATK(
            INDEXING_REF_GENOME.out.reference_fasta,
            INDEXING_REF_GENOME.out.gatkDict,
            INDEXING_REF_GENOME.out.samtoolsIndex,
            BASE_QU_SCO_RECA.out.reaclBam,
            BASE_QU_SCO_RECA.out.reaclIdx.map { id, file -> file }
        )

    } else {
        FullModeOutput()
	INDEXING_REF_GENOME(RefGenChannel)
	
        ALIGN_TO_REF_GENOME(
            INDEXING_REF_GENOME.out.reference_fasta,
            INDEXING_REF_GENOME.out.combinedIdx.collect(),
            ReadsToBeAligned,
            Target
        )

        CALL_SNPs_GATK(
            INDEXING_REF_GENOME.out.reference_fasta,
            INDEXING_REF_GENOME.out.gatkDict,
            INDEXING_REF_GENOME.out.samtoolsIndex,
            ALIGN_TO_REF_GENOME.out.bams,
            ALIGN_TO_REF_GENOME.out.bamIdx.map { id, file -> file }
        )
    }
}
