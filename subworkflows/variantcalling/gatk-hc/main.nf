// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../../.logos'
include { DelMoroVarCallOutput	} from '../../../.logos'
	
 
include { CallVariant     } from '../../../modules/06.0_VariantSNPcall-HC.nf' 
include { CreateGVCF      } from '../../../modules/06.0_VariantSNPcall-HC.nf'  
include { CombineGvcfs    } from '../../../modules/06.0_VariantSNPcall-HC.nf'  
include { GenotypeGvcfs   } from '../../../modules/06.0_VariantSNPcall-HC.nf' 
include { GenerateStats   } from '../../../modules/06.2_VarMetrics.nf' 
 
workflow CALL_VARIANT_GATK {

    take:
    ref_gen_channel
    dictREF
    samidxREF
    BamToVarCall
    bedtarget
 
    main: 
    if (params.stepmode && params.exec == "callvar" ) { DelMoroVarCallOutput() }
        
    // Determine if we are using local reference or igenome fasta retrieving
    def referFileChannel = params.reference ?: params.igenome
       
    if  (params.mode 		== null && 
   	 referFileChannel 	!= null ){
	
	CallVariant 	(  ref_gen_channel
    	                  ,dictREF.collect()
    	                  ,samidxREF.collect()
    	                  ,BamToVarCall
    	                  ,bedtarget) 
 //bedtarget.view()
	///// Metrics Extracting from vcfs 
	GenerateStats	(CallVariant.out.CallVariantvcf)

    } else if ( referFileChannel 	!= null && 
		params.mode 		== 'cohort' ){	// generate vcf for all inputs 
	
	CreateGVCF	( ref_gen_channel
	                 ,dictREF.collect()
	                 ,samidxREF.collect()
	                 ,BamToVarCall
	                 ,bedtarget)

    
    
	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 

	GenotypeGvcfs 	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),CombineGvcfs.out.CohortVcf )

	GenerateStats	( GenotypeGvcfs.out )  

 			
    }  else { 
	print("\033[31m Error: Invalid or missing parameters.\n" )
	print(" Please specify valid parameters:\n"              )
	print(" --reference option (--reference reference ) \n" )
	print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "  )
	print(" --mode cohort  ( Default : null --> will generate a single vcfs )\n "    ) 
        print(" --caller deepvariant ( Default : no caller --> variant calling with gatk )\n " ) 
        print(" ---------------------------------------------------------------------------\n"  )
        print(" For more information:\n"                                        )
        print("   >>  View the help menu: nextflow main.nf --help\n"            )
        print("   >>  Check parameters: nextflow main.nf --params\n\033[37m"    ) 
    } 
}


