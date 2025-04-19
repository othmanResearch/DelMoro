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
    if ( params.ivcf1		== null &&
 	 params.ivcf2		== null && 
	 params.knownsite1 	!= null && 
	 params.knownsite2 	!= null ){
	
	if (params.reference 	!= null && 
	    params.bam 		!= null ){
		    
	    DelMoroBQSROutput()
	   	
	    IndexKNownSite1 (knwonSite1)
	    IndexKNownSite2 (knwonSite2) 	
	   	
	    BaseRecalibrator (  ref_gen_channel,
			   	dictREF.collect(),
			   	samidxREF.collect(),
			   	MappedReads,
			   	knwonSite1,
			   	IndexKNownSite1.out,
			   	knwonSite2,
			   	IndexKNownSite2.out				)
	   
	    ApplyBQSR ( 	MappedReads,
				BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)	)	
							
	    IndexRecalBam ( ApplyBQSR.out.recal_bam.collectFile(sort: true) )
		
	    } else { DelMoroWelcome() 
		     print("\033[31m Please specify valid parameters:\n"			)
		     print(" --reference option (--reference reference ) \n"			)
		     print(" --bam option (--bam CSVs/4_samplesheetForBamFiles.csv )\n "	)
		     print("\033[31m  --knownSite1  option --knownSite1 option \n"		)
		     print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
	    } 
	 		   
    } else if (	params.ivcf1 		!= null && 
               	params.ivcf2 		!= null && 
           	params.knownsite1 	== null && 
          	params.knownsite2 	== null ){
	     	
         if ( params.IVCF && 
	   !( params.IVCF.containsKey(params.ivcf1) && 
	      params.IVCF.containsKey(params.ivcf2)  ) ){                
   	     
   	     DelMoroWelcome()
    	     exit 1, "The provided genome '${params.ivcf1}' or '${params.ivcf2}' is not available. Available genomes: ${params.IVCF.keySet().join(', ')}"
	 }
	
	
	if ( params.reference 	!= null && 
	     params.bam 	!= null ){
							
	     DelMoroBQSROutput()			
					 
	     DownloadKns1()
	     DownloadKns2()
	     IndexKNownSite1 (DownloadKns1.out)
	     IndexKNownSite2 (DownloadKns2.out) 	
							   	
	     BaseRecalibrator ( ref_gen_channel,
 				dictREF.collect(),
	      			samidxREF.collect(),
				MappedReads,
				DownloadKns1.out,
				IndexKNownSite1.out,
				DownloadKns2.out,
				IndexKNownSite2.out				)
							
	    ApplyBQSR ( 	MappedReads,
		        	BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)	)	
													
	    IndexRecalBam ( ApplyBQSR.out.recal_bam.collectFile(sort: true) )

		    } else { DelMoroWelcome() 
		  	     print("\033[31m Please specify valid parameters:\n"			)
			     print(" --reference option (--reference reference ) \n"			)
			     print(" --bam option (--bam CSVs/4_samplesheetForBamFiles.csv )\n "	)
			     print("\033[31m   --ivcf1  option --ivcf2 option  \n"			)
			     print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
			   } 
	
	} else { 
	 DelMoroWelcome() 
	 print("\033[31m Please specify valid parameters:\n"			)
	 print(" --reference option (--reference reference ) \n"			)
	 print(" --bam option (--bam CSVs/4_samplesheetForBamFiles.csv )\n "	)
	 print("\033[31m  --knownsite1  option --knownsite2 option \n"		)
	 print("\033[31m  or \n"							)
	 print("\033[31m   --ivcf1  option --ivcf2 option  \n"			)
	 print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
    } 
}
	
	   				

 
