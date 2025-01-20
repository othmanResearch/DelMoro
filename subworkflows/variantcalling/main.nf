// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../logos'
include { DelMoroVarCallOutput	} from '../../logos'
	
include { BaseRecalibrator	} from '../../modules/5_variantSNPcall.nf'  
include { ApplyBQSR		} from '../../modules/5_variantSNPcall.nf'  
include { IndexRecalBam		} from '../../modules/5_variantSNPcall.nf'  
include { RecalHaploCall	} from '../../modules/5_variantSNPcall.nf'  
include { VarToTable		} from '../../modules/5_variantSNPcall.nf'  
include { SnpFilter		} from '../../modules/5_variantSNPcall.nf'  
include { CreateGVCF		} from '../../modules/5_variantSNPcall.nf'  
include { IndexGVCF		} from '../../modules/5_variantSNPcall.nf'  
include { CombineGvcfs		} from '../../modules/5_variantSNPcall.nf'  
include { GenotypeGvcfs		} from '../../modules/5_variantSNPcall.nf' 


workflow Call_SNPs_with_GATK {

  take:
    ref_gen_channel
    dictREF
    samidxREF
    MappedReads
    IDXBAM
    knwonSite1
    IDXknS1
    knwonSite2
    IDXknS2

  main: 

   if  (params.exec 		!= null && 
   	params.generate 	== null && 
   	params.reference 	!= null && 
   	params.bam 		!= null && 
   	params.knownSite1 	!= null && 
   	params.knownSite2 	!= null ){
   		
   	DelMoroVarCallOutput()
       			 
	BaseRecalibrator( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  MappedReads,
			  knwonSite1,
			  IDXknS1,
			  knwonSite2,
			  IDXknS2								)
	
	ApplyBQSR	( MappedReads,
			  BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)		)	
						
 	IndexRecalBam	( ApplyBQSR.out.recal_bam.collectFile(sort: true)			)
				
	RecalHaploCall	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  ApplyBQSR.out.recal_bam.collectFile(sort: true),
			  IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)
   	
	VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   			
   	SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   	
   	CreateGVCF	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  ApplyBQSR.out.recal_bam.collectFile(sort: true),
			  IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)
													
	IndexGVCF	( CreateGVCF.out.g_vcf_Recal.collectFile(sort: true)			)
				
	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.collect(sort: true),
			  IndexGVCF.out.IDXVCFiles.collect(sort: true)				) 
	
	GenotypeGvcfs 	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CombineGvcfs.out.CohorteVcf.collectFile(sort: true)			)  

   		} else if ( params.exec 	!= null &&  
   			    params.reference 	!= null && 
   			    params.bam 		!= null && 
   			    params.knownSite1 	!= null && 
   			    params.knownSite2 	!= null &&
			    params.generate 	== 'onlyVCF' ){	// generate vcf for all inputs 
  	 
	  		    DelMoroVarCallOutput()
	     	
	   	  	    BaseRecalibrator ( ref_gen_channel,
			    		       dictREF.collect(),
					       samidxREF.collect(),
					       MappedReads,
					       knwonSite1,
					       IDXknS1,
					       knwonSite2,
					       IDXknS2					  			)
		
			    ApplyBQSR ( MappedReads,
                                        BaseRecalibrator.out.BQSR_Table.collectFile(sort:true) 			)	
								

		 	    IndexRecalBam  ( ApplyBQSR.out.recal_bam.collectFile(sort: true)			)
					
			    RecalHaploCall ( ref_gen_channel,
					     dictREF.collect(),
					     samidxREF.collect(),
					     ApplyBQSR.out.recal_bam.collectFile(sort: true),
					     IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)	 	)
	   
	   		    VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
	   	
	   		    SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
	   	
   			} else if ( params.exec 	!= null &&  
   				    params.reference 	!= null && 
   				    params.bam 		!= null && 
   				    params.knownSite1 	!= null && 
   				    params.knownSite2 	!= null&&
   				    params.generate 	== 'cohorteGVCF' ){ // Generate one file : the cohorte vcf
   	
   			
		   		    DelMoroVarCallOutput()
		     		    BaseRecalibrator	( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  MappedReads,
							  knwonSite1,
							  IDXknS1,
							  knwonSite2,
							  IDXknS2							)
				    ApplyBQSR		( MappedReads,
							  BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)	)	
		 		    IndexRecalBam	( ApplyBQSR.out.recal_bam.collectFile(sort: true)		)
					
		   		    CreateGVCF		( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  ApplyBQSR.out.recal_bam.collectFile(sort: true),
							  IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)		)

				    IndexGVCF		( CreateGVCF.out.g_vcf_Recal.collectFile(sort: true)		)
			
				    CombineGvcfs	( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  CreateGVCF.out.g_vcf_Recal.collect(sort: true),
							  IndexGVCF.out.IDXVCFiles.collect(sort: true)			) 
			
				    GenotypeGvcfs 	( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  CombineGvcfs.out.CohorteVcf.collectFile(sort: true)		)  
		 		
				}  else { 
				    DelMoroWelcome() 
				    print("\033[31m Please specify valid parameters:\n")
				    print(" --reference option (--reference reference ) \n")
				    print(" --bam option (--bam CSVs/4_samplesheetForBamFiles.csv )\n ")
				    print("\033[31m  --knownSite1 option ( --knownSite1 knownsites/file1.vcf ) \n")
			  	    print("\033[31m  and \n")
			  	    print("\033[31m  --knownSite2 option ( --knownSite2 knownsites/file2.vcf ) \n")
				    print("optional : --generate option (--generate onlyVCF / cohorteGVCF )\n ")  
			    	    print("For details, run: nextflow main.nf --exec params\n\033[37m")
	   } 
}



 

	    
	    
	
