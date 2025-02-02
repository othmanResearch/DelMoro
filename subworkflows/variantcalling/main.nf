// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroVarCallOutput	} from '../../.logos'
	
 
include { RecalHaploCall	} from '../../modules/6_variantSNPcall.nf'  
include { VarToTable		} from '../../modules/6_variantSNPcall.nf'  
include { SnpFilter		} from '../../modules/6_variantSNPcall.nf'  
include { CreateGVCF		} from '../../modules/6_variantSNPcall.nf'  
include { IndexGVCF		} from '../../modules/6_variantSNPcall.nf'  
include { CombineGvcfs		} from '../../modules/6_variantSNPcall.nf'  
include { GenotypeGvcfs		} from '../../modules/6_variantSNPcall.nf' 


workflow Call_SNPs_with_GATK {

    take:
	ref_gen_channel
	dictREF
	samidxREF
	BamToVarCall
	IDXBAM
 
    main: 

    if  (params.exec 		!= null && 
    	 params.generate 	== null && 
   	 params.reference 	!= null && 
   	 params.tovarcall	!= null ){
   		
   	 DelMoroVarCallOutput()
       			 
				
	 RecalHaploCall	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  BamToVarCall,
			  IDXBAM.collect()				)
   	
	 VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   			
   	 SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   	
   	 CreateGVCF	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  BamToVarCall,
			  IDXBAM.collect()		)
													
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
   			    params.tovarcall	!= null &&
			    params.generate 	== 'onlyVCF' ){	// generate vcf for all inputs 
  	 
	  		    DelMoroVarCallOutput()
	     				
			    RecalHaploCall ( ref_gen_channel,
					     dictREF.collect(),
					     samidxREF.collect(),
					     BamToVarCall,
					     IDXBAM.collect()	 	)
	   
	   		    VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
	   	
	   		    SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
	   	
   			} else if ( params.exec 	!= null &&  
   				    params.reference 	!= null && 
   				    params.tovarcall	!= null &&
   				    params.generate 	== 'cohorteGVCF' ){ // Generate one file : the cohorte vcf
   	
   			
		   		    DelMoroVarCallOutput()
		     				
		   		    CreateGVCF		( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  BamToVarCall,
							  IDXBAM.collect()			)

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
				    print("\033[31m Please specify valid parameters:\n"					)
				    print(" --reference option (--reference reference ) \n"				)
				    print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	)
				    print("optional : --generate option (--generate onlyVCF / cohorteGVCF )\n "		)  
			    	    print("For details, run: nextflow main.nf --exec params\n\033[37m"			)
	   } 
}



 

	    
	    
	
