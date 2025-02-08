// Assembly subworkflow 

include { DelMoroWelcome  	 } from '../../.logos'
include { DelMoroAssemblyOutput	 } from '../../.logos'
	
include { alignReadsToRef	 } from '../../modules/4_Assembly.nf' 
include { alignReadsToRefBWAMEM2 } from '../../modules/4_Assembly.nf' 
include { assignReadGroup	 } from '../../modules/4_Assembly.nf' 
include { markDuplicates 	 } from '../../modules/4_Assembly.nf' 
include { IndexBam		 } from '../../modules/4_Assembly.nf' 
include { Extractregion		 } from '../../modules/4_Assembly.nf' 
include { GenerateStat		 } from '../../modules/4_Assembly.nf' 
include { IndexBam as IndexRegion} from '../../modules/4_Assembly.nf' 
 
include { BamCoverage		 } from '../../modules/4_CoverageStat.nf' 
include { BamTargetCoverage	 } from '../../modules/4_CoverageStat.nf' 

workflow ALIGN_TO_REF_GENOME {
  take:
    ref_gen_channel
    indexes
    READS
    target
  main: 
    
    // Case: No region specified
  if ( params.aligner == null ) {
 
 	if ( params.reference 	!= null && 
 	     params.tobealigned != null && 
 	     params.generate 	== null && 
 	     params.region 	== null && 
 	     params.bedtarget 	== null ){ 
 	     
 	     	DelMoroAssemblyOutput()
        
        	alignReadsToRef	(ref_gen_channel, indexes.collect(),READS )			   	
		assignReadGroup	(alignReadsToRef.out.collectFile(sort: true))
		markDuplicates	(assignReadGroup.out.collectFile( sort: true))
         	IndexBam	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)   	
		GenerateStat	(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true), 
				 markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
		BamCoverage 	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true),IndexBam.out.collect())
		
		// Case: CHECK COVERAGE IN TARGETD REGION FROM BED FILE 

		} else if ( params.reference 	!= null && 
			    params.tobealigned 	!= null && 
			    params.region 	== null && 
			    params.generate 	== 'coverage' && 
			    params.bedtarget 	!== null ){ 
			    
			    	DelMoroAssemblyOutput()
        		
        			alignReadsToRef	  (ref_gen_channel, indexes.collect(),READS 				) 
				assignReadGroup	  (alignReadsToRef.out.collectFile(sort: true)				) 
				markDuplicates	  (assignReadGroup.out.collectFile( sort: true)				) 
     				IndexBam	  (markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
				GenerateStat	  (assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true), 
						   markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
				BamTargetCoverage (markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true),
					  	   IndexBam.out.collect(), target					)
	
			// Case: Region specified Extract BAM REGION FILE
	
			} else if ( params.reference 	!= null && 
				    params.tobealigned 	!= null && 
				    params.generate 	== null && 
				    (params.region 	==~ /^[a-zA-Z0-9]+:\d+-\d+$/) ){  
				    	
				    	DelMoroAssemblyOutput()
			
					alignReadsToRef	(ref_gen_channel, indexes.collect(),READS 	 		      	) 
					assignReadGroup	(alignReadsToRef.out.collectFile(sort: true)) 
					markDuplicates	(assignReadGroup.out.collectFile( sort: true)) 
     					IndexBam	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true) 	)  
                			Extractregion 	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true), 
                					 IndexBam.out.IDXBAM.collect()					 	)
					IndexRegion	(Extractregion.out.collectFile(sort: true)				) 
					GenerateStat	(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true),
						 	 markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)
		 			} else {  
	 					DelMoroWelcome()
    						print("\033[31m Please specify valid parameters:\n"				)
    						print("  --reference option ( --reference <reference-path> )\n"			)
   						print("  --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n"	)
    						print("  --region ( formatted as 'chr:start-end' )\n"				)
    						print("  --generate coverage --bedtarget (bedfile)\n"				)
    	    					print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n"		)
    						print("For details, run: nextflow main.nf --exec params\n\033[37m"		)
						}
	
  } else  if ( params.aligner == "bwamem2" ) {
 
 	if ( params.reference 	!= null && 
 	     params.tobealigned != null && 
 	     params.generate 	== null && 
 	     params.region 	== null && 
 	     params.bedtarget 	== null ){ 
 	     
 	     	DelMoroAssemblyOutput()
        
        	alignReadsToRefBWAMEM2	(ref_gen_channel, indexes.collect(),READS 				)			   	
		assignReadGroup		(alignReadsToRefBWAMEM2.out.collectFile(sort: true))
		markDuplicates		(assignReadGroup.out.collectFile( sort: true))
         	IndexBam		(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)   	
		GenerateStat		(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true), 
					 markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
		BamCoverage 		(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true),
					 IndexBam.out.collect()							)
		
		// Case: CHECK COVERAGE IN TARGETD REGION FROM BED FILE 

		} else if ( params.reference 	!= null && 
			    params.tobealigned 	!= null && 
			    params.region	== null && 
			    params.generate 	== 'coverage' && 
			    params.bedtarget 	!== null ){ 
			    
			    	DelMoroAssemblyOutput()
        		
        			alignReadsToRefBWAMEM2	(ref_gen_channel, indexes.collect(),READS 				) 
				assignReadGroup		(alignReadsToRefBWAMEM2.out.collectFile(sort: true)			) 
				markDuplicates		(assignReadGroup.out.collectFile( sort: true)) 
     				IndexBam		(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
				GenerateStat		(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true),
							 markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	) 
				BamTargetCoverage 	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true),
							 IndexBam.out.collect(),target						)
	
			// Case: Region specified Extract BAM REGION FILE
	
			} else if ( params.reference 	!= null && 
				    params.tobealigned 	!= null && 
				    params.generate 	== null && 
				    (params.region 	==~ /^[a-zA-Z0-9]+:\d+-\d+$/) ){  
				    
				    	DelMoroAssemblyOutput()
			
					alignReadsToRefBWAMEM2	(ref_gen_channel, indexes.collect(),READS 				) 
					assignReadGroup		(alignReadsToRefBWAMEM2.out.collectFile(sort: true)			) 
					markDuplicates		(assignReadGroup.out.collectFile( sort: true)) 
     					IndexBam		(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)  
                			Extractregion 		(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true), 
                						 IndexBam.out.IDXBAM.collect())
					IndexRegion		(Extractregion.out.collectFile(sort: true)				) 
					GenerateStat		(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true),
								 markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)
		 			} else {  
	 					
	 					DelMoroWelcome()
    						print("\033[31m Please specify valid parameters:\n")
    						print("  --reference option ( --reference <reference-path> )\n")
   						print("  --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n")
    						print("  --region ( formatted as 'chr:start-end' )\n")
    						print("  --generate coverage --bedtarget (bedfile)\n")
    	    					print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n")
    						print("For details, run: nextflow main.nf --exec params\n\033[37m")
					}
 	} else {  
	 	DelMoroWelcome()
    		print("\033[31m Please specify valid parameters:\n")
    		print("  --reference option ( --reference <reference-path> )\n")
   		print("  --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n")
    		print("  --region ( formatted as 'chr:start-end' )\n")
    		print("  --generate coverage --bedtarget (bedfile)\n")
    	    	print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n")
    		print("For details, run: nextflow main.nf --exec params\n\033[37m")
	}
  
}
 
 
 
