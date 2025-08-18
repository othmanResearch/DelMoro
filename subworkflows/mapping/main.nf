// Assembly subworkflow 

include { DelMoroWelcome  	  } from '../../.logos'
include { DelMoroAssemblyOutput	  } from '../../.logos'
	
include { AlignReadsToRef	  } from '../../modules/4_Assembly.nf' 
include { AlignReadsToRefBwaMem2  } from '../../modules/4_Assembly.nf' 
include { AssignReadGroup	  } from '../../modules/4_Assembly.nf' 
include { MarkDuplicates	  } from '../../modules/4_Assembly.nf' 
include { IndexBam		  } from '../../modules/4_Assembly.nf' 
include { Extractregion	 	  } from '../../modules/4_Assembly.nf' 
include { GenerateStat	 	  } from '../../modules/4_Assembly.nf' 
include { IndexBam as IndexRegion } from '../../modules/4_Assembly.nf' 
 
include { BamCoverage	 	  } from '../../modules/4_CoverageStat.nf' 
include { BamTargetCoverage	  } from '../../modules/4_CoverageStat.nf'

include { BigWig   		  } from '../../modules/4_BamToBigWig.nf'
include { BigWigCoveragePlots	  } from '../../modules/4_BigWigPlotting.nf'

include { AlignmentMetrics	  } from '../../modules/4_BamMetrics.nf' 
include { InsertMetrics		  } from '../../modules/4_BamMetrics.nf' 
include { GcBiasMetrics 	  } from '../../modules/4_BamMetrics.nf' 
include { Qualimap		  } from '../../modules/4_BamMetrics.nf'

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
	      	
	    if (params.bamqc) {
	    	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam) 
		BamCoverage 	(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)
		BigWig		(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)
	    	BigWigCoveragePlots (BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out   
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
	    
	    if (params.bamqc) {
	    	GenerateStat 		(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam ) 
	   	BamTargetCoverage 	(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out.IDXBAM, target )
	   	BigWig			(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	    	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	    	InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
		Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out
	
	// Case: Region specified Extract BAM REGION FILE
	
	} else if ( referFileChannel 	!= null && 
		    params.tobealigned	!= null && 
		    params.generate 	== null && 
		    (params.region	==~ /^[a-zA-Z0-9]+:\d+-\d+$/) ){  

	    AlignReadsToRef	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRef.out) 
	    MarkDuplicates	(AssignReadGroup.out) 
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam 	)  
	    Extractregion 	(MarkDuplicates.out.sorted_markduplicates_bam, IndexBam.out.IDXBAM )
	    IndexRegion		(Extractregion.out ) 

	    
	    if (params.bamqc) {
		GenerateStat		(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam )
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)	 
	        BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out

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
 bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
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
	    
	    if (params.bamqc) { 
	     	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam ) 
	    	BamCoverage		(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out )
	    	BigWig			(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out )
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg )
	 	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out

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
	    
	    if (params.bamqc) {
	    	GenerateStat	(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam ) 
	    	BamTargetCoverage	(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out,target	)
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)		 
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	       	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam	  )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out

	// Case: Region specified Extract BAM REGION FILE
	
    } else if ( referFileChannel 	!= null && 
		inputFileChannel 	!= null && 
		params.generate 	== null && 
		(params.region 	==~ /^[a-zA-Z0-9]+:\d+-\d+$/) ){  

	    AlignReadsToRefBwaMem2	(ref_gen_channel, indexes.collect(),READS ) 
	    AssignReadGroup	(AlignReadsToRefBwaMem2.out ) 
	    MarkDuplicates	(AssignReadGroup.out) 
	    IndexBam		(MarkDuplicates.out.sorted_markduplicates_bam	)  
	    Extractregion	(MarkDuplicates.out.sorted_markduplicates_bam, IndexBam.out.IDXBAM)
	    IndexRegion		(Extractregion.out	) 
   
	    if (params.bamqc) {
	    	GenerateStat		(AssignReadGroup.out.sorted_labeled_bam,MarkDuplicates.out.sorted_markduplicates_bam )
	        BigWig			(MarkDuplicates.out.sorted_markduplicates_bam,IndexBam.out)
	    	BigWigCoveragePlots	(BigWig.out, params.mindepth, params.saveImg)
	      	AlignmentMetrics( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel )
	        InsertMetrics	( MarkDuplicates.out.sorted_markduplicates_bam )
	        GcBiasMetrics	( MarkDuplicates.out.sorted_markduplicates_bam, ref_gen_channel ) 
	        Qualimap	( MarkDuplicates.out.sorted_markduplicates_bam )
	    }
	    emit : 
	    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
	    bamIdx = IndexBam.out

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
    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
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
  
}

