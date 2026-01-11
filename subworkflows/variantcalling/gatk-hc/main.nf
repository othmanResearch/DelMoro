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
 
    main: 
    if (params.stepmode && params.exec == "callvar" ) { DelMoroVarCallOutput() }
    // Determine if we have valid BAM inputs
    def hasBamTovarInput = params.fullmode ? true : (params.tovarcall != null)
    // Determine if we are using local reference or igenome fasta retrieving
    def referFileChannel = params.reference ?: params.igenome
    
    if (!hasBamTovarInput) {
	DelMoroWelcome()
	error("\n\033[31mERROR: Missing required BAM input.\n" +
	    "In --fullmode, BAMs should come from alignment step.\n" +
            "Without --fullmode, please specify --tovarcall parameter.\033[0m")
        }
        
    if  (params.mode 		== null && 
   	 referFileChannel 	!= null ){
	
	CallVariant 	(  ref_gen_channel
    	                  ,dictREF.collect()
    	                  ,samidxREF.collect()
    	                  ,BamToVarCall ) 
 
	///// Metrics Extracting from vcfs 
	GenerateStats	(CallVariant.out.CallVariantvcf)

    } else if ( referFileChannel 	!= null && 
		params.mode 		== 'cohort' ){	// generate vcf for all inputs 
	
	CreateGVCF	( ref_gen_channel
	                 ,dictREF.collect()
	                 ,samidxREF.collect()
	                 ,BamToVarCall )

    
    
	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 

	GenotypeGvcfs 	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),CombineGvcfs.out.CohortVcf )

	GenerateStats	( GenotypeGvcfs.out )  

 			
    }  else { 
	DelMoroWelcome() 
	print("\033[31m Please specify valid parameters:\n" )
	print(" --reference option (--reference reference ) \n" )
	print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	)
	print("optional : --mode cohort  ( Default : null --> will generate a single vcfs )\n " )  
	print("For details, run: nextflow main.nf --exec params\n\033[37m" )
    } 
}


