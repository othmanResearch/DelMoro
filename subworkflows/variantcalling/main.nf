def printOutput() { 
log.info"""

\033[37m  DDDDDDDDDDDDD                           \033[37mLLLLLLLLLLL             \033[31mMMMMMMMM               MMMMMMMM                                                      
\033[37m  D::::::::::::DDD                        \033[37mL:::::::::L             \033[31mM:::::::M             M:::::::M                                                      
\033[37m  D:::::::::::::::DD                      \033[37mL:::::::::L             \033[31mM::::::::M           M::::::::M                                                      
\033[37m  DDD:::::DDDDD:::::D                     \033[37mLL:::::::LL             \033[31mM:::::::::M         M:::::::::M                                                      
\033[37m   D:::::D    D:::::D    eeeeeeeeeeee     \033[37mL:::::L                 \033[31mM::::::::::M       M::::::::::M\033[37m   ooooooooooo   rrrrr   rrrrrrrrr      ooooooooooo   
\033[37m   D:::::D     D:::::D  ee::::::::::::ee  \033[37mL:::::L                 \033[31mM:::::::::::M     M:::::::::::M\033[37m oo:::::::::::oo r::::rrr:::::::::r   oo:::::::::::oo 
\033[37m   D:::::D     D:::::D e::::::eeeee:::::ee\033[37mL:::::L                 \033[31mM:::::::M::::M   M::::M:::::::M\033[37mo:::::::::::::::or:::::::::::::::::r o:::::::::::::::o
\033[37m   D:::::D     D:::::De::::::e     e:::::e\033[37mL:::::L                 \033[31mM::::::M M::::M M::::M M::::::M\033[37mo:::::ooooo:::::orr::::::rrrrr::::::ro:::::ooooo:::::o
\033[37m   D:::::D     D:::::De:::::::eeeee::::::e\033[37mL:::::L                 \033[31mM::::::M  M::::M::::M  M::::::M\033[37mo::::o     o::::o r:::::r     r:::::ro::::o     o::::o
\033[37m   D:::::D     D:::::De:::::::::::::::::e \033[37mL:::::L                 \033[31mM::::::M   M:::::::M   M::::::M\033[37mo::::o     o::::o r:::::r     rrrrrrro::::o     o::::o
\033[37m   D:::::D     D:::::De::::::eeeeeeeeeee  \033[37mL:::::L                 \033[31mM::::::M    M:::::M    M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m   D:::::D    D:::::D e:::::::e           \033[37mL:::::L         LLLLLLLL\033[31mM::::::M     MMMMM     M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m DDD:::::DDDDD:::::D  e::::::::e          \033[37mLL:::::::LLLLLLLLL:::::L\033[31mM::::::M               M::::::M\033[37mo:::::ooooo:::::o r:::::r            o:::::ooooo:::::o
\033[37m D:::::::::::::::DD    e::::::::eeeeeeee  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37mo:::::::::::::::o r:::::r            o:::::::::::::::o
\033[37m D::::::::::::DDD       ee:::::::::::::e  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37m oo:::::::::::oo  r:::::r             oo:::::::::::oo 
\033[37m DDDDDDDDDDDDD            eeeeeeeeeeeeee  \033[37mLLLLLLLLLLLLLLLLLLLLLLLL\033[31mMMMMMMMM               MMMMMMMM\033[37m   ooooooooooo    rrrrrrr               ooooooooooo   

                                                                    
\033[37m                                                                        \033[31m X
\033[37m         o O        o O       o O       o o       o O        o O o       o                    o O       o       o O       o O      o O       o O    
\033[37m       o | | O    o | | O   o | | O   o | |O     o| | O    o | | | O      o                 o | | O   o | O   o | | O    o| | O  o | | O   o | | O
\033[37m O | | | | | | | O  | | | | O | | | | O | | o | O | | | | O  | | | | o O O O O O O O O O O O || | | | O | | | O | | | | O | | | |  | | | | | | | | | | O 
\033[37m       o | | o    O | | o   O | | o   O | o      O| | o    O | | | o          o             O | | o   O | o   O | | o   O | | o  O | | o   O | | o 
\033[37m         o o        O o       O o       O         O o        O o o             o              O o       O       O o       O o      O o       O o     
                                                                                \033[31m o o X\033[37m
                                                                                
\033[32m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\033[32m ✔ VCF Files 			=\033[37m ${params.outdir}/Mapping/Variants
\033[32m ✔ Base Recalibration 		=\033[37m ${params.outdir}/Mapping
\033[32m ✔ Bam indexes 			=\033[37m ${params.outdir}/Indexes/BamFiles
\033[32m ✔ Threads 			=\033[37m ${params.cpus}
\033[32m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	"""
	}

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
  	printOutput()
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


	
