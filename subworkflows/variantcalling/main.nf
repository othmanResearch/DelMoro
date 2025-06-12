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

include { GenerateStats 	} from '../../modules/6_varMetrics.nf' 
 
workflow CALL_SNPs_GATK {

    take:
	ref_gen_channel
	dictREF
	samidxREF
	BamToVarCall
	IDXBAM
 
    main: 

    if  (params.mode 		== null && 
   	 params.reference 	!= null && 
   	 params.tovarcall	!= null ){
   		
   	 DelMoroVarCallOutput()
       			 
				
	 RecalHaploCall	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  BamToVarCall,
			  IDXBAM.collect()				)
   	
	 VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect()	)
   			
   	 SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect()	)
   	
   	 ///// Metrics Extracting from vcfs  
	 GenerateStats	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect()	) 
   	 ////
   	 CreateGVCF	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  BamToVarCall,
			  IDXBAM.collect()		)
													
	 IndexGVCF	( CreateGVCF.out.g_vcf_Recal.collectFile(sort: true), CreateGVCF.out.CreateGVCFidx.collectFile()			)
				
	 CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.collect(sort: true),
			  IndexGVCF.out.IDXVCFiles.collect(sort: true)				) 
	
	 GenotypeGvcfs 	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CombineGvcfs.out.CohortVcf.collectFile(sort: true),
			  CombineGvcfs.out.CombineGvcfsidx.collect()		)  
			  
	
   		} else if ( params.reference 	!= null && 
   			    params.tovarcall	!= null &&
			    params.mode 	== 'onlyVCF' ){	// generate vcf for all inputs 
  	 
	  		    DelMoroVarCallOutput()
	     				
			    RecalHaploCall ( ref_gen_channel,
					     dictREF.collect(),
					     samidxREF.collect(),
					     BamToVarCall,
					     IDXBAM.collect()	 	)
	   
	   		    VarToTable 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect()	)
	   	
	   		    SnpFilter 	( RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect()	)
 			    
 			    ///// Metrics Extracting from vcfs 
			    GenerateStats	(RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true), RecalHaploCall.out.RecalHaploCallidx.collect())
	   		    /////
	   		    
   			} else if ( params.reference 	!= null && 
   				    params.tovarcall	!= null &&
   				    params.mode 	== 'cohortGVCF' ){ // Generate one file : the cohort vcf
   	
   			
		   		    DelMoroVarCallOutput()
		     				
		   		    CreateGVCF		( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  BamToVarCall,
							  IDXBAM.collect()			)

				    IndexGVCF		( CreateGVCF.out.g_vcf_Recal.collectFile(sort: true), CreateGVCF.out.CreateGVCFidx.collectFile()		)
			
				    CombineGvcfs	( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  CreateGVCF.out.g_vcf_Recal.collect(sort: true),
							  IndexGVCF.out.IDXVCFiles.collect(sort: true)			) 
			
				    GenotypeGvcfs 	( ref_gen_channel,
							  dictREF.collect(),
							  samidxREF.collect(),
							  CombineGvcfs.out.CohortVcf.collectFile(sort: true),
			  				  CombineGvcfs.out.CombineGvcfsidx.collect()			)
			  				  
				    GenerateStats	( GenotypeGvcfs.out) 
				    
				}  else { 
				    DelMoroWelcome() 
				    print("\033[31m Please specify valid parameters:\n"					)
				    print(" --reference option (--reference reference ) \n"				)
				    print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	)
				    print("optional : --mode option (--mode onlyVCF / cohortGVCF )\n "		)  
			    	    print("For details, run: nextflow main.nf --exec params\n\033[37m"			)
	   } 
}



 

	    
	    
	
