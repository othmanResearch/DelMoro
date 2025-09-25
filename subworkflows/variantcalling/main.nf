// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroVarCallOutput	} from '../../.logos'
	
 
include { CallVariant		} from '../../modules/6_VariantSNPcall.nf' 
include { CreateGVCF		} from '../../modules/6_VariantSNPcall.nf'  
include { IndexGVCF		} from '../../modules/6_VariantSNPcall.nf'  
include { CombineGvcfs		} from '../../modules/6_VariantSNPcall.nf'  
include { GenotypeGvcfs		} from '../../modules/6_VariantSNPcall.nf' 

include { GenerateStats 	} from '../../modules/6_VarMetrics.nf' 
 
workflow CALL_SNPs_GATK {

    take:
    ref_gen_channel
    dictREF
    samidxREF
    BamToVarCall
    IDXBAM
 
    main: 
    if (params.stepmode && params.exec == "callsnp" ) { DelMoroVarCallOutput() }
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
			
	CallVariant	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),BamToVarCall,IDXBAM.collect() )
	///// Metrics Extracting from vcfs  
	GenerateStats	( CallVariant.out.CallVariantvcf, CallVariant.out.CallVariantidx	) 
	CreateGVCF	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),BamToVarCall,IDXBAM.collect() )
	IndexGVCF	( CreateGVCF.out.g_vcf_Recal, CreateGVCF.out.CreateGVCFidx			)

	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.map { id, file -> file }.collect().map { files -> tuple("cohort", files) },  
			  IndexGVCF.out.IDXVCFiles.map { id, file -> file }.collect().map { files -> tuple("cohort", files) }  )
 							
	GenotypeGvcfs 	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),CombineGvcfs.out.CohortVcf,CombineGvcfs.out.CombineGvcfsidx.collect() )  
			  
	
    } else if ( referFileChannel 	!= null && 
		params.mode 		== 'onlyVCF' ){	// generate vcf for all inputs 

    	CallVariant 	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),BamToVarCall,IDXBAM.collect() )
	///// Metrics Extracting from vcfs 
	GenerateStats	(CallVariant.out.CallVariantvcf, CallVariant.out.CallVariantidx)
    } else if ( referFileChannel 	!= null && 
		params.mode 		== 'cohortGVCF' ){ // Generate one file : the cohort vcf

	CreateGVCF	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),BamToVarCall,IDXBAM.collect() )
	IndexGVCF	( CreateGVCF.out.g_vcf_Recal, CreateGVCF.out.CreateGVCFidx )
	CombineGvcfs	( ref_gen_channel,
			  dictREF.collect(),
			  samidxREF.collect(),
			  CreateGVCF.out.g_vcf_Recal.map { id, file -> file }.collect().map { files -> tuple("cohort", files) },  
			  IndexGVCF.out.IDXVCFiles.map { id, file -> file }.collect().map { files -> tuple("cohort", files) }	) 
			
	GenotypeGvcfs 	( ref_gen_channel,dictREF.collect(),samidxREF.collect(),CombineGvcfs.out.CohortVcf,CombineGvcfs.out.CombineGvcfsidx.collect() )
	GenerateStats	( GenotypeGvcfs.out) 
			
    }  else { 
	DelMoroWelcome() 
	print("\033[31m Please specify valid parameters:\n" )
	print(" --reference option (--reference reference ) \n" )
	print(" --tovarcall option (--tovarcall CSVs/5_samplesheetReclibFiles.csv )\n "	)
	print("optional : --mode option (--mode onlyVCF / cohortGVCF )\n " )  
	print("For details, run: nextflow main.nf --exec params\n\033[37m" )
    } 
}


