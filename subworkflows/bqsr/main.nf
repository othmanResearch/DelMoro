// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroBQSROutput	} from '../../.logos'

include { DownloadKns1		} from '../../modules/05.0_Bqsr.nf'  
include { DownloadKns2		} from '../../modules/05.0_Bqsr.nf'  
include { IndexVcf as IndexKNownSite1	} from '../../modules/05.0_Bqsr.nf'  
include { IndexVcf as IndexKNownSite2	} from '../../modules/05.0_Bqsr.nf'  
include { BaseRecalibrator	} from '../../modules/05.0_Bqsr.nf'  
include { ApplyBQSR		} from '../../modules/05.0_Bqsr.nf'    
include { IndexRecalBam		} from '../../modules/05.0_Bqsr.nf'

include { AlignmentMetrics	} from '../../modules/04.1_BamMetrics.nf'
include { InsertMetrics		} from '../../modules/04.1_BamMetrics.nf'
include { GcBiasMetrics 	} from '../../modules/04.1_BamMetrics.nf'
include { Qualimap		} from '../../modules/04.1_BamMetrics.nf'

include { BigWig		} from '../../modules/04.2_BamToBigWig.nf'
include { BigWigCoveragePlots	} from '../../modules/04.3_BigWigPlotting.nf'




workflow BASE_QU_SCO_RECA {
    take:
    ref_gen_channel
    dictREF
    samidxREF
    MappedReads  
    IDXBAM
    knwonSite1
    knwonSite2
   
    main: 
    if (params.stepmode && params.exec == "bqsr") { DelMoroBQSROutput() }

    // Determine if we have valid BAM inputs
    def hasBamInput = params.fullmode ? true : (params.bam != null)
    
    if (!hasBamInput) {
    DelMoroWelcome()
    error("\n\033[31mERROR: Missing required BAM input.\n" +
      "In --fullmode, BAMs should come from alignment step.\n" +
      "Without --fullmode, please specify --bam parameter.\033[0m")
    }

    // Main processing logic
    if (params.ivcf1 	  == null && 
 	params.ivcf2 	  == null && 
 	params.knownsite1 != null && 
 	params.knownsite2 != null) {
           	
    	BaseRecalibrator	( ref_gen_channel
    	                         ,dictREF.collect()
    	                         ,samidxREF.collect()
    	                         ,MappedReads
    	                         ,knwonSite1  // includes its index
    	                         ,knwonSite2  // includes its index
    	                         ) 
    	                       
    	                       
        ApplyBQSR		(MappedReads.join(BaseRecalibrator.out.BQSR_Table) )	
	IndexRecalBam		(ApplyBQSR.out.recal_bam)    

	if (params.report) {
	    BigWig		(ApplyBQSR.out.recal_bam, IndexRecalBam.out)
	    BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
            AlignmentMetrics   	(ApplyBQSR.out.recal_bam, ref_gen_channel)
	    InsertMetrics	(ApplyBQSR.out.recal_bam)
	    GcBiasMetrics	(ApplyBQSR.out.recal_bam, ref_gen_channel) 
	    Qualimap		(ApplyBQSR.out.recal_bam)
    	}
    
    emit:
    reaclBam = ApplyBQSR.out.recal_bam   
    reaclIdx = IndexRecalBam.out
    
    } else if ( params.ivcf1		!= null && 
    		params.ivcf2 		!= null && 
      		params.knownsite1 	== null && 
      		params.knownsite2 	== null ) {
    
	if ( params.IVCF 			     && 
	     !(params.IVCF.containsKey(params.ivcf1) && 
	     params.IVCF.containsKey(params.ivcf2))  ){    
	DelMoroWelcome()
	error("The provided genome '${params.ivcf1}' or '${params.ivcf2}' is not available. Available genomes: ${params.IVCF.keySet().join(', ')}")
	}

        DownloadKns1()
	DownloadKns2()
	IndexKNownSite1(DownloadKns1.out.igenome_ch.map { file -> tuple(file.baseName, file) })
	IndexKNownSite2(DownloadKns2.out.igenome_ch.map { file -> tuple(file.baseName, file) }) 
 
	BaseRecalibrator	( ref_gen_channel
	                         ,dictREF.collect()
	                         ,samidxREF.collect()
	                         ,MappedReads
	                         ,DownloadKns1.out.igenome_ch.map { file -> tuple(file.baseName, file) }.join(IndexKNownSite1.out).first()
	                         ,DownloadKns2.out.igenome_ch.map { file -> tuple(file.baseName, file) }.join(IndexKNownSite2.out).first()
	                        )
	                        
	ApplyBQSR		(MappedReads.join(BaseRecalibrator.out.BQSR_Table) )

	IndexRecalBam		(ApplyBQSR.out.recal_bam)
	
	if (params.report) {
	    BigWig		(ApplyBQSR.out.recal_bam, IndexRecalBam.out)
	    BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
 	    AlignmentMetrics	(ApplyBQSR.out.recal_bam, ref_gen_channel)
	    InsertMetrics	(ApplyBQSR.out.recal_bam)
	    GcBiasMetrics	(ApplyBQSR.out.recal_bam, ref_gen_channel) 
	    Qualimap		(ApplyBQSR.out.recal_bam)
	    }
	    
	emit:
	reaclBam = ApplyBQSR.out.recal_bam   
	reaclIdx = IndexRecalBam.out
    } else { 
 
    error("\033[31m Please specify valid parameters:\n   --reference option (--reference reference)\n   ${params.fullmode ? '' : '--bam option (--bam CSVs/4_samplesheetForBamFiles.csv)'}\n Either:\n   --knownsite1 and --knownsite2 options\n OR   \n   --ivcf1 and --ivcf2 options\nFor details, run: nextflow main.nf --exec params\033[0m\n")
    
    }
    emit:
    reaclBam = ApplyBQSR.out.recal_bam   
    reaclIdx = IndexRecalBam.out  
}

