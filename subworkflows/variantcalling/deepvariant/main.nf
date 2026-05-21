// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../../.logos'
include { DelMoroVarCallOutput	} from '../../../.logos'
	
 
include { deepVariant     } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include {  glnexus        } from '../../../modules/06.1_VariantSNPcall-DV.nf'
include { GenerateStats   } from '../../../modules/06.2_VarMetrics.nf' 

include { AddVariantID    } from '../../../modules/06.3_VariantIDAnnotat.nf'
include { RsAnnotation    } from '../../../modules/06.3_VariantIDAnnotat.nf'

include { SortVCF         } from '../../../modules/06.4_splitmultilocus.nf'
include { NormalizeVCF    } from '../../../modules/06.4_splitmultilocus.nf'


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

        if (  params.splitAllele  == null &&
              params.rsid         != null  ){ 
              AddVariantID  ( deepVariant.out.CallVariantvcf)   
              RsAnnotation  ( AddVariantID.out, AnnotRefVCF ) 
        
        } else if ( params.splitAllele  != null && 
                    params.rsid         == null ){
                    AddVariantID    (deepVariant.out.CallVariantvcf)         
                    SortVCF         ( AddVariantID.out) 
	            NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                	
                  } else if ( params.splitAllele  != null && 
                              params.rsid         != null ){
                              AddVariantID  (deepVariant.out.CallVariantvcf)   
                              SortVCF       ( AddVariantID.out) 
	                      NormalizeVCF  ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                              RsAnnotation  ( NormalizeVCF.out, AnnotRefVCF )            	                  
                    } else { AddVariantID   (deepVariant.out.CallVariantvcf)   }

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
	
        if (  params.splitAllele  == null &&
              params.rsid         != null  ){ 
              
              RsAnnotation  ( glnexus.out, AnnotRefVCF ) 
        
        } else if ( params.splitAllele  != null && 
                    params.rsid         == null ){

                    SortVCF         ( glnexus.out) 
	            NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                	
                  } else if ( params.splitAllele  != null && 
                              params.rsid         != null ){

                              SortVCF       ( glnexus.out) 
	                      NormalizeVCF  ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                              RsAnnotation  ( NormalizeVCF.out, AnnotRefVCF )            	                  
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


