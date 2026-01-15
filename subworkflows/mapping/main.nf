// Assembly subworkflow 

include { DelMoroWelcome  	  } from '../../.logos'
include { DelMoroAssemblyOutput	  } from '../../.logos'
	
include { AlignReadsToRef	  } from '../../modules/04.0_Assembly.nf' 
include { AlignReadsToRefBwaMem2  } from '../../modules/04.0_Assembly.nf' 
include { AssignReadGroup	  } from '../../modules/04.0_Assembly.nf' 
include { MarkDuplicates	  } from '../../modules/04.0_Assembly.nf' 
include { IndexBam		  } from '../../modules/04.0_Assembly.nf' 
include { Extractregion	 	  } from '../../modules/04.0_Assembly.nf' 
include { GenerateStat	 	  } from '../../modules/04.0_Assembly.nf' 
include { IndexBam as IndexRegion } from '../../modules/04.0_Assembly.nf' 

include { AlignmentMetrics	  } from '../../modules/04.1_BamMetrics.nf' 
include { InsertMetrics		  } from '../../modules/04.1_BamMetrics.nf' 
include { GcBiasMetrics 	  } from '../../modules/04.1_BamMetrics.nf' 
include { Qualimap		  } from '../../modules/04.1_BamMetrics.nf'

include { BigWig   		  } from '../../modules/04.2_BamToBigWig.nf'

include { BigWigCoveragePlots	  } from '../../modules/04.3_BigWigPlotting.nf'

include { BamCoverage	 	  } from '../../modules/04.4_CoverageStat.nf' 
include { BamTargetCoverage	  } from '../../modules/04.4_CoverageStat.nf'



workflow ALIGN_TO_REF_GENOME {
     take:
     ref_gen_channel
    indexes
     READS
     target
 
    main: 
    def inputFileChannel = params.input ?: params.tobealigned 
    def referFileChannel = params.reference ?: params.igenome
    
    if (params.stepmode && params.exec == "align" ) { DelMoroAssemblyOutput() }
    // Case: No region specified
    if ( params.aligner == null ) {
 
	if (referFileChannel 	!= null && 
	    inputFileChannel 	!= null && 
 	    params.generate 	== null && 
  	    params.region	== null && 
   	    params.bedtarget 	== null ){ 
 
	    AlignReadsToRef	(ref_gen_channel, indexes.collect(),READS )		   	
	    AssignReadGroup	(AlignReadsToRef.out.sorted_bam)
	    MarkDuplicates	(AssignReadGroup.out.sorted_labeled_bam)
	    IndexBam	(MarkDuplicates.out.sorted_markduplicates_bam) 
	      	
	    if (params.report) {
	    	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam) 
		BamCoverage 	(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
		BigWig		(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots (BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	    }
	    
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out  
	    bamWithIdx = bams.join(bamIdx)
	// Case: CHECK COVERAGE IN TARGETD REGION FROM BED FILE 

	} else if ( referFileChannel 	!= null && 
		inputFileChannel 	!= null && 
		params.region 		== null && 
		params.generate 	== 'coverage' && 
		params.bedtarget	!== null ){ 
	
	    AlignReadsToRef	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRef.out ) 
	    MarkDuplicates  	(AssignReadGroup.out ) 
	    IndexBam	  	(MarkDuplicates.out.sorted_markduplicates_bam	) 
	    
	    if (params.report) {
	    	GenerateStat 		(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam ) 
	   	BamTargetCoverage 	(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) .IDXBAM, target )
	   	BigWig			(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	    	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	    	InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) 	  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
		Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) 	  )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
            bamWithIdx = bams.join(bamIdx)
	// Case: Region specified Extract BAM REGION FILE
	
	} else if ( referFileChannel 	!= null && 
		    params.tobealigned	!= null && 
		    params.generate 	== null && 
		    params.region	){  

	    AlignReadsToRef	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRef.out) 
	    MarkDuplicates	(AssignReadGroup.out) 
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam 	)  
	    Extractregion 	(MarkDuplicates.out.sorted_markduplicates_bam, IndexBam.out.IDXBAM )
	    IndexRegion		(Extractregion.out ) 

	    
	    if (params.report) {
		GenerateStat		(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam )
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )	 
	        BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
	    bamWithIdx = bams.join(bamIdx)
	} else {  
	    DelMoroWelcome()
	    print("\033[31m Please specify valid parameters:\n"	)
	    print("  --reference option ( --reference <reference-path> )\n"		)
	    print("  --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n"	)
	    print("  --region ( formatted as 'chr:start-end' )\n"	)
	    print("  --generate coverage --bedtarget (bedfile)\n"	)
	    print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n"	)
	    print("For details, run: nextflow main.nf --exec params\n\033[37m"	)
	}
    emit: 	
    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
    bamWithIdx = bams.join(bamIdx)
    } else  if ( params.aligner == "bwamem2" ) {
 
	if ( referFileChannel 	!= null && 
	     inputFileChannel 	!= null && 
	     params.generate 	== null && 
	     params.region	== null && 
	     params.bedtarget 	== null ){ 
 		 
	
	    AlignReadsToRefBwaMem2	(ref_gen_channel, indexes.collect(),READS )		   	
	    AssignReadGroup	(AlignReadsToRefBwaMem2.out )
	    MarkDuplicates	(AssignReadGroup.out )
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam )
	    
	    if (params.report) { 
	     	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam ) 
	    	BamCoverage		(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWig			(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg )
	 	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
	    bamWithIdx = bams.join(bamIdx)
	// Case: CHECK COVERAGE IN TARGETD REGION FROM BED FILE 

	} else if ( referFileChannel 	!= null && 
		inputFileChannel 	!= null && 
		params.region		== null && 
		params.generate 	== 'coverage' && 
		params.bedtarget 	!== null ){ 

	    AlignReadsToRefBwaMem2	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRefBwaMem2.out ) 
	    MarkDuplicates	(AssignReadGroup.out )  
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam ) 
	    
	    if (params.report) {
	    	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam ) 
	    	BamTargetCoverage	(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) ,target	)
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )		 
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	       	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
	    bamWithIdx = bams.join(bamIdx)
	// Case: Region specified Extract BAM REGION FILE
	
    } else if ( referFileChannel 	!= null && 
		inputFileChannel 	!= null && 
		params.generate 	== null && 
		params.region ){  

	    AlignReadsToRefBwaMem2	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRefBwaMem2.out ) 
	    MarkDuplicates	(AssignReadGroup.out) 
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam	)  
	    Extractregion	(MarkDuplicates.out.sorted_markduplicates_bam, IndexBam.out.IDXBAM)
	    IndexRegion		(Extractregion.out	) 
   
	    if (params.report) {
	    	GenerateStat		(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam )
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	      	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
	    bamWithIdx = bams.join(bamIdx)
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
    emit:	
    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
    bamWithIdx = bams.join(bamIdx)    
    } else {  
	DelMoroWelcome()
	print("\033[31m Please specify valid parameters:\n")
	print("  --reference option ( --reference <reference-path> )\n")
	print("  --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n")
	print("  --region ( formatted as 'chr:start-end' )\n")
	print("  --generate coverage --bedtarget (bedfile)\n")
	print("  --aligner bwamem2 , Default bwa ( not to be mentionned ) \n")
	print("  --metrics , To Generate Bam Metrics \n")
	print("For details, run: nextflow main.nf --exec params\n\033[37m")
    }
	
    emit : 
    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
    bamWithIdx = bams.join(bamIdx)
  
}

