// Variant Calling subworkflow 

include {DelMoroVarCallOutput} from '../../logos'	
include {BaseRecalibrator; ApplyBQSR; IndexRecalBam; RecalHaploCall; VarToTable; SnpFilter; CreateGVCF; IndexGVCF; CombineGvcfs; GenotypeGvcfs} from '../../modules/5_variantSNPcall.nf' 


workflow Call_SNPs_with_GATK {

take:
    ref_gen_channel
    dictREF
    samidxREF
    MappedReads
    IDXBAM
    knwonSite1
    IDXknS1
    knwonSite2
    IDXknS2

  main: 
   
   if  ( params.generate == null ) {
   		
   	DelMoroVarCallOutput()
       			 
	BaseRecalibrator(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				MappedReads,
				knwonSite1,
				IDXknS1,
				knwonSite2,
				IDXknS2					)
	
	ApplyBQSR	(	MappedReads,
				BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)			)	
						
 	IndexRecalBam	(	ApplyBQSR.out.recal_bam.collectFile(sort: true)				)
				
	RecalHaploCall	(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				ApplyBQSR.out.recal_bam.collectFile(sort: true),
				IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)
   	
	VarToTable 	(	RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   			
   	SnpFilter 	(	RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   	
   	CreateGVCF	(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				ApplyBQSR.out.recal_bam.collectFile(sort: true),
				IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)
													
	IndexGVCF	( 	CreateGVCF.out.g_vcf_Recal.collectFile(sort: true)			)
				
	CombineGvcfs	(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				CreateGVCF.out.g_vcf_Recal.collect(sort: true),
				IndexGVCF.out.IDXVCFiles.collect(sort: true)				) 
	
	GenotypeGvcfs 	(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				CombineGvcfs.out.CohorteVcf.collectFile(sort: true)			)  

   		} else if ( params.generate == 'onlyVCF') {	// generate vcf for all inputs 
  	 
  		DelMoroVarCallOutput()
     	
   	  	BaseRecalibrator(	ref_gen_channel,
					dictREF.collect(),
					samidxREF.collect(),
					MappedReads,
					knwonSite1,
					IDXknS1,
					knwonSite2,
					IDXknS2					)
	
		ApplyBQSR	(	MappedReads,
					BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)			)	
							

	 	IndexRecalBam	(	ApplyBQSR.out.recal_bam.collectFile(sort: true)				)
				
		RecalHaploCall	(	ref_gen_channel,
					dictREF.collect(),
					samidxREF.collect(),
					ApplyBQSR.out.recal_bam.collectFile(sort: true),
					IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)
   
   		VarToTable 	(	RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   	
   		SnpFilter 	(	RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
   	
   		} else if ( params.generate == 'cohorteGVCF') {	 // Generate one file : the cohorte vcf
   			
   			DelMoroVarCallOutput()
     			BaseRecalibrator(	ref_gen_channel,
						dictREF.collect(),
						samidxREF.collect(),
						MappedReads,
						knwonSite1,
						IDXknS1,
						knwonSite2,
						IDXknS2					)
			ApplyBQSR	(	MappedReads,
						BaseRecalibrator.out.BQSR_Table.collectFile(sort:true)			)	
 			IndexRecalBam	(	ApplyBQSR.out.recal_bam.collectFile(sort: true)				)
			
   			CreateGVCF	(	ref_gen_channel,
						dictREF.collect(),
						samidxREF.collect(),
						ApplyBQSR.out.recal_bam.collectFile(sort: true),
						IndexRecalBam.out.IDXRECALBAM.collectFile(sort: true)			)

			IndexGVCF	( 	CreateGVCF.out.g_vcf_Recal.collectFile(sort: true)			)
	
			CombineGvcfs	(	ref_gen_channel,
						dictREF.collect(),
						samidxREF.collect(),
						CreateGVCF.out.g_vcf_Recal.collect(sort: true),
						IndexGVCF.out.IDXVCFiles.collect(sort: true)				) 
	
			GenotypeGvcfs 	(	ref_gen_channel,
						dictREF.collect(),
						samidxREF.collect(),
						CombineGvcfs.out.CohorteVcf.collectFile(sort: true)			)  
		 		
	}

}


	
