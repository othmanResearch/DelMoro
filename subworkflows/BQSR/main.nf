// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroBQSROutput	} from '../../.logos'

include { DownloadKns1		} from '../../modules/5_BQSR.nf'  
include { DownloadKns2		} from '../../modules/5_BQSR.nf'  
include { IndexKNownSites as IndexKNownSite1	} from '../../modules/5_BQSR.nf'  
include { IndexKNownSites as IndexKNownSite2	} from '../../modules/5_BQSR.nf'  
include { BaseRecalibrator	} from '../../modules/5_BQSR.nf'  
include { ApplyBQSR		} from '../../modules/5_BQSR.nf'    
include { IndexRecalBam		} from '../../modules/5_BQSR.nf'    


workflow BaseQuScoReac {
    take:
	ref_gen_channel
	dictREF
	samidxREF
	MappedReads
	IDXBAM
	knwonSite1
	knwonSite2
   
    main: 
    if (params.exec		!= null && 
	params.reference 	!= null && 
	params.bam 		!= null && 
	params.knownSite1 	!= null && 
	params.knownSite2 	!= null &&
	params.ivcf1		== null &&
	params.ivcf2		== null ){
	    
	DelMoroBQSROutput()
   	
	IndexKNownSite1 (knwonSite1)
	IndexKNownSite2 (knwonSite2) 	
   	
	BaseRecalibrator ( 
		ref_gen_channel,
		dictREF.collect(),
		samidxREF.collect(),
		MappedReads,
		knwonSite1,
		IndexKNownSite1.out,
		knwonSite2,
		IndexKNownSite2.out	)
	
	ApplyBQSR ( 
		MappedReads,
		BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)	)	
						
	IndexRecalBam ( ApplyBQSR.out.recal_bam.collectFile(sort: true) )
 		   
	} else if ( params.exec		!= null && 
		    params.reference 	!= null && 
		    params.bam 		!= null && 
		    params.ivcf1	!= null &&
		    params.ivcf2	!= null &&
		    params.knownSite1 	== null && 
   		    params.knownSite2 	== null ){
						
   		    DelMoroBQSROutput()			
				 
		    DownloadKns1()
		    DownloadKns2()
		    IndexKNownSite1 (DownloadKns1.out)
		    IndexKNownSite2 (DownloadKns2.out) 	
						   	
		   BaseRecalibrator( 
		   	ref_gen_channel,
			dictREF.collect(),
			samidxREF.collect(),
			MappedReads,
			DownloadKns1.out,
			IndexKNownSite1.out,
			DownloadKns2.out,
			IndexKNownSite2.out	)
						
		   ApplyBQSR ( 
		   	MappedReads,
			BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)	)	
												
		    IndexRecalBam ( ApplyBQSR.out.recal_bam.collectFile(sort: true) )
						 		   
			} else { 
				DelMoroWelcome() 
				print("\033[31m Please specify valid parameters:\n"			)
				print(" --reference option (--reference reference ) \n"			)
				print(" --bam option (--bam CSVs/4_samplesheetForBamFiles.csv )\n "	)
				print("\033[31m  --knownSite1  option --knownSite1 option \n"		)
				print("\033[31m  or \n"							)
				print("\033[31m   --ivcf1  option --ivcf2 option  \n"			)
				print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
			} 
}


 
