// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../../.logos'
include { DelMoroVarCallOutput	} from '../../../.logos'
	
 
include { deepVariant     } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include {  glnexus        } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include { GenerateStats   } from '../../../modules/06.2_VarMetrics.nf' 

workflow CALL_VARIANT_DEEPVARIANT {

    take:
    ref_gen_channel
    dictREF
    samidxREF
    BamToVarCall
 
    main: 
    if (params.stepmode && params.exec == "callvar" ) { DelMoroVarCallOutput() }

    // Determine if we are using local reference or igenome fasta retrieving
    def referFileChannel = params.reference ?: params.igenome
        
    if  (params.mode 		== null && 
   	 referFileChannel 	!= null &&
   	 params.modelType       != null &&
   	 params.caller          == "deepvariant" ){
	
	deepVariant 	( ref_gen_channel, dictREF.collect(), samidxREF.collect(), BamToVarCall ) 

	///// Metrics Extracting from vcfs 
	GenerateStats	(deepVariant.out.CallVariantvcf)


    } else if ( referFileChannel 	!= null &&
                params.modelType        != null && 
                params.mode 		== "cohort" &&
                params.caller           == "deepvariant" ){	// generate vcf for all inputs 
	
	deepVariant	( ref_gen_channel, dictREF.collect(), samidxREF.collect(), BamToVarCall )
	
        GenerateStats	( deepVariant.out.CallVariantvcf)

	glnexus         ( deepVariant.out.deepGvcf.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 
			
    }  else { 
        print("\033[31m Error: Invalid or missing parameters.\n" )
	print(" Please specify valid parameters:\n"      )
	print(" --reference option (--reference reference ) \n" )
	print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	  )
	print(" --caller deepvariant ( Default : no caller --> variant calling with gatk )\n "   ) 
	print(" --modelType <WGS|WES|PACBIO|ONT_R104|HYBRID_PACBIO_ILLUMINA|MASSEQ> )\n "        ) 
	print(" --mode cohort  ( Default : null --> will generate a single vcfs )\n " )  
        print(" ---------------------------------------------------------------------------\n"    )
        print(" For more information:\n"                                        )
        print("   >>  View the help menu: nextflow main.nf --help\n"            )
        print("   >>  Check parameters: nextflow main.nf --params\n\033[37m"    ) 
    } 
}


