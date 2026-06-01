// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../../.logos'
include { DelMoroVarCallOutput	} from '../../../.logos'
	
 
include { CallVariant     } from '../../../modules/06.0_VariantSNPcall-HC.nf' 
include { CreateGVCF      } from '../../../modules/06.0_VariantSNPcall-HC.nf'  
include { CombineGvcfs    } from '../../../modules/06.0_VariantSNPcall-HC.nf'  
include { GenotypeGvcfs   } from '../../../modules/06.0_VariantSNPcall-HC.nf' 
include { GenerateStats   } from '../../../modules/06.2_VarMetrics.nf'

include { AlleleBalance   } from '../../../modules/06.3_AlleleBalance.nf' 
include { AddVariantID    } from '../../../modules/06.4_VariantIDAnnotat.nf'
include { RsAnnotation    } from '../../../modules/06.4_VariantIDAnnotat.nf'

include { SortVCF         } from '../../../modules/06.5_splitmultilocus.nf'
include { NormalizeVCF    } from '../../../modules/06.5_splitmultilocus.nf'

include { GetSamples      } from '../../../modules/06.6_splitBySample.nf'
include { SplitBySample   } from '../../../modules/06.6_splitBySample.nf'


workflow CALL_VARIANT_GATK {

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
        referFileChannel 	!= null ){
	
	CallVariant 	(  ref_gen_channel, dictREF.collect(), samidxREF.collect(), BamToVarCall ,bedtarget) 
	///// Metrics Extracting from vcfs 
	GenerateStats	( CallVariant.out.CallVariantvcf)
	AlleleBalance   ( CallVariant.out )
	
        if (  params.splitAllele  == null &&
              params.rsid         != null  ){ 
              AddVariantID  ( AlleleBalance.out)   
              RsAnnotation  ( AddVariantID.out, AnnotRefVCF ) 
        
        } else if ( params.splitAllele  != null && 
                    params.rsid         == null ){
                    AddVariantID    (AlleleBalance.out)         
                    SortVCF         ( AddVariantID.out)
                    NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                	
                  } else if ( params.splitAllele  != null && 
                              params.rsid         != null ){
                              AddVariantID    (AlleleBalance.out)   
                              SortVCF       ( AddVariantID.out)
                              NormalizeVCF  ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                              RsAnnotation  ( NormalizeVCF.out, AnnotRefVCF )            	                  
                    } else { AddVariantID   ( AlleleBalance.out)   }
  	
    } else if ( referFileChannel 	!= null && 
		params.mode 		== 'cohort' ){	// generate vcf for all inputs 
	
	CreateGVCF	( ref_gen_channel, dictREF.collect(), samidxREF.collect(), BamToVarCall, bedtarget)

    
    
	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.map { id, gvcf, idx -> tuple("cohort", gvcf, idx) }.groupTuple() ) 

	GenotypeGvcfs 	( ref_gen_channel, dictREF.collect(), samidxREF.collect(), CombineGvcfs.out.CohortVcf )

	GenerateStats	( GenotypeGvcfs.out )  
        AlleleBalance   ( GenotypeGvcfs.out )
        
        if (  params.splitAllele  == null &&
              params.rsid         != null  ){ 
              AddVariantID  ( AlleleBalance.out)   
              RsAnnotation  ( AddVariantID.out, AnnotRefVCF ) 
              
              if (params.splitSample) {
                  GetSamples ( RsAnnotation.out)
                  SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs 
                                                            -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	      }                
        } else if ( params.splitAllele  != null && 
                    params.rsid         == null ){
                    
                    AddVariantID    ( AlleleBalance.out)         
                    SortVCF         ( AddVariantID.out)
                    NormalizeVCF    ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                    
                    if (params.splitSample) {
	                GetSamples ( NormalizeVCF.out)
	                SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs 
	                                                          -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	            }          
                  } else if ( params.splitAllele  != null && 
                              params.rsid         != null ){
                              
                              AddVariantID  ( AlleleBalance.out)   
                              SortVCF       ( AddVariantID.out) 
                              NormalizeVCF  ( SortVCF.out, ref_gen_channel, dictREF.collect(), samidxREF.collect() ) 
                              RsAnnotation  ( NormalizeVCF.out, AnnotRefVCF )  
                              
                              if (params.splitSample) {
	                            GetSamples ( RsAnnotation.out)
	                            SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs 
	                                                                    -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	                      }
	                      
                    } else { AddVariantID   ( AlleleBalance.out)
                             
                             if (params.splitSample) {
	                        GetSamples ( AddVariantID.out)
	                        SplitBySample ( GetSamples.out.flatMap { cohort_id, vcf, tbi, samplesIDs 
	                                                                 -> samplesIDs.trim().split('\n').collect { sampleId -> tuple(sampleId, vcf, tbi) } } )
	                     }
                      }

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


