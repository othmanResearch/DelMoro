// Variant Calling subworkflow 

include {DelMoroVarCallOutput} from '../../logos'	
include {RawHaploCall; BaseRecalibrator; ApplyBQSR; IndexRecalBam; RecalHaploCall; VarToTable; SnpFilter; CreateGVCF; IndexGVCF; CombineGvcfs; GenotypeGvcfs} from '../../modules/5_variantSNPcall.nf' 


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
  	DelMoroVarCallOutput()
       	RawHaploCall	(	ref_gen_channel,
				dictREF.collect(),
				samidxREF.collect(),
				MappedReads,
				IDXBAM.collect()				)

	
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
   
   	VarToTable 	(	RawHaploCall.out.vcf_HaplotypeCaller_Raw.collectFile(sort: true),
   				RecalHaploCall.out.vcf_HaplotypeCaller_Recal.collectFile(sort: true)	)
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
				CombineGvcfs.out.Combinedvcf.collectFile(sort: true)			)  

  /*emit:
  */

}


	
