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
   	 referFileChannel 	!= null &&
   	 params.modelType       != null &&
   	 params.caller          == "deepvariant" ){
	
	deepVariant 	(  ref_gen_channel
    	                  ,dictREF.collect()
    	                  ,samidxREF.collect()
    	                  ,BamToVarCall ) 

	///// Metrics Extracting from vcfs 
	GenerateStats	(deepVariant.out.CallVariantvcf)


    } else if ( referFileChannel 	!= null &&
                params.modelType        != null && 
                params.mode 		== "cohort" &&
                params.caller           == "deepvariant" ){	// generate vcf for all inputs 
	
	deepVariant	( ref_gen_channel
	                 ,dictREF.collect()
	                 ,samidxREF.collect()
	                 ,BamToVarCall )
        GenerateStats	(deepVariant.out.CallVariantvcf)

	glnexus         (deepVariant.out.deepGvcf.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 



    


 			
    }  else { 
	print("\033[31m Please specify valid parameters:\n" )
	print("\t--reference option (--reference reference ) \n" )
	print("\t--tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	)
	print("\t--caller deepvariant ( Default : no caller --> variant calling with gatk )\n " ) 
	print("\t--modelType <WGS|WES|PACBIO|ONT_R104|HYBRID_PACBIO_ILLUMINA|MASSEQ> )\n " ) 
	print("\toptional : --mode cohort  ( Default : null --> will generate a single vcfs )\n " )  
	print("\tFor details, run: nextflow main.nf --exec params\n\033[37m" )
    } 
}


