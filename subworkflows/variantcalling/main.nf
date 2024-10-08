// Variant Calling subworkflow 

include {DelMoroWelcome; DelMoroVarCallOutput} from '../../logos'	
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

   if  (params.exec != null && params.generate == null && params.refGenome != null && params.BamFiles != null ) {
   		
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

   		} else if (params.exec != null && params.generate == 'onlyVCF' && params.refGenome != null && params.BamFiles != null) {	// generate vcf for all inputs 
  	 
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
   	
   		} else if (params.exec != null && params.generate == 'cohorteGVCF' && params.refGenome != null && params.BamFiles != null) {	 // Generate one file : the cohorte vcf
   			
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
		 		
	}  else { 
	    DelMoroWelcome() 
	    print("\033[31m please specify --refGenome option (--refGenome reference ) and --BamFiles option (--BamFiles CSVs/4.. )\n If needed please specify --generate option (--generate onlyVCF / cohorteGVCF/)\n For more details nextflow main.nf --exec ShowParams \033[37m")  }
       
}


	
