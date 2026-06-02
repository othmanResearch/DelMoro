// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../../.logos'
include { DelMoroVarCallOutput	} from '../../../.logos'
	
 
include { deepVariant     } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include {  glnexus        } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include { GenerateStats   } from '../../../modules/06.2_VarMetrics.nf' 

include { AlleleBalance   } from '../../../modules/06.3_AlleleBalance.nf' 
include { AddVariantID    } from '../../../modules/06.4_VariantIDAnnotat.nf'
include { RsAnnotation    } from '../../../modules/06.4_VariantIDAnnotat.nf'

include { SortVCF         } from '../../../modules/06.5_splitmultilocus.nf'
include { NormalizeVCF    } from '../../../modules/06.5_splitmultilocus.nf'

include { GetSamples      } from '../../../modules/06.6_splitBySample.nf'
include { SplitBySample   } from '../../../modules/06.6_splitBySample.nf'

workflow CALL_VARIANT_DEEPVARIANT {

    take:
    ref_gen_channel
    dictREF
    samidxREF
    BamToVarCall
    bedtarget
    AnnotRefVCF

 
    main: 
    if (params.stepmode && params.exec == "callvar" ) { DelMoroVarCallOutput() }

    // Determine if we are using local reference or igenome fasta retrieving
    def referFileChannel = params.reference ?: params.igenome
        
    if  (params.mode 		== null && 
   	 referFileChannel 	!= null &&
   	 params.modelType       != null &&
   	 params.caller          == "deepvariant" ){
	
	deepVariant 	( ref_gen_channel
	                  ,dictREF.collect()
	                  ,samidxREF.collect()
	                  ,BamToVarCall
	                  ,bedtarget ) 

	///// Metrics Extracting from vcfs 
	GenerateStats	(deepVariant.out.CallVariantvcf)
	
	AddVariantID  	( deepVariant.out.CallVariantvcf  )  
	SortVCF         ( AddVariantID.out	)
	NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect()	) 
	AlleleBalance   ( NormalizeVCF.out )
	
	if ( params.rsid	!= null  ){ 
            RsAnnotation  ( deepVariant.out.CallVariantvcf, AnnotRefVCF ) 
        } 

    } else if ( referFileChannel 	!= null &&
                params.modelType        != null && 
                params.mode 		== "cohort" &&
                params.caller           == "deepvariant" ){	// generate vcf for all inputs 
	
	deepVariant	( ref_gen_channel
	                  ,dictREF.collect()
	                  ,samidxREF.collect()
	                  ,BamToVarCall
	                  ,bedtarget )
	
        GenerateStats	( deepVariant.out.CallVariantvcf)

	glnexus         ( deepVariant.out.deepGvcf.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 

        AddVariantID  	( glnexus.out )  
        SortVCF         ( AddVariantID.out	)
        NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect()	) 
        AlleleBalance   ( NormalizeVCF.out )
	
	if ( params.rsid  != null  ){ 
	    RsAnnotation  ( AlleleBalance.out, AnnotRefVCF ) 
	    
	    if (params.splitSample) {
	        GetSamples ( RsAnnotation.out)
	        SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	    }
	} else if (params.splitSample) {
	    GetSamples ( AlleleBalance.out)	
	    SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	} 
	
                          
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


