// Assembly subworkflow 

include { DelMoroWelcome  	  } from '../../.logos'
include { DelMoroAssemblyOutput	  } from '../../.logos'
	
include { AlignReadsToRef	  } from '../../modules/04.0_Assembly.nf' 
include { AlignReadsToRefBwaMem2  } from '../../modules/04.0_Assembly.nf' 
include { AssignReadGroup	  } from '../../modules/04.0_Assembly.nf' 
include { MarkDuplicates	  } from '../../modules/04.0_Assembly.nf' 
include { IndexBam		  } from '../../modules/04.0_Assembly.nf' 
include { GenerateStat	 	  } from '../../modules/04.0_Assembly.nf' 

include { AlignmentMetrics	  } from '../../modules/04.1_BamMetrics.nf' 
include { InsertMetrics		  } from '../../modules/04.1_BamMetrics.nf' 
include { GcBiasMetrics 	  } from '../../modules/04.1_BamMetrics.nf' 
include { Qualimap		  } from '../../modules/04.1_BamMetrics.nf'

include { BigWig   		  } from '../../modules/04.2_BamToBigWig.nf'

include { BigWigCoveragePlots	  } from '../../modules/04.3_BigWigPlotting.nf'

include { BamCoverage	 	  } from '../../modules/04.4_CoverageStat.nf' 

workflow ALIGN_TO_REF_GENOME {
     take:
     ref_gen_channel
     indexes
     READS
     bedtarget
 
    main: 
    def inputFileChannel = params.input ?: params.tobealigned 
    def referFileChannel = params.reference ?: params.igenome
    
    if (params.stepmode && params.exec == "align" ) { DelMoroAssemblyOutput() }

    if ( params.aligner == null ) {
 
        if (referFileChannel 	!= null && 
            inputFileChannel 	!= null ){ 
 
	    AlignReadsToRef (ref_gen_channel, indexes.collect(),READS )		   	
	    AssignReadGroup (AlignReadsToRef.out.sorted_bam)
	    MarkDuplicates  (AssignReadGroup.out.sorted_labeled_bam)
	    IndexBam        (MarkDuplicates.out.sorted_markduplicates_bam)
	    BamCoverage     ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out),bedtarget ) 
	    
	    if (params.report ) {
	    	GenerateStat	    ( AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam) 
		BigWig		    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots ( BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	        GcBiasMetrics	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
            
            } 
        } else {  
            error("\033[31m Error: Invalid or missing parameters.\n\n" +
                  " Please specify valid parameters:\n\n" +
                  " --reference option ( --reference <reference-path> )\n\n" +
                  " --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n\n" +
                  " --aligner bwamem2 , Default bwa ( not to be mentionned ) \n\n" +
                  " --report , To Generate Bam Metrics \n\n"+
                  "------------------------------------------------------------\n\n" +
                  " For more information:\n\n" +
                  "   >>  View the help menu: nextflow main.nf --help\n\n" +
                  "   >>  Check parameters: nextflow main.nf --params\n\n \033[37m ") 
        }       
       
    } else  if ( params.aligner == "bwamem2" ) {
 
        if ( referFileChannel 	!= null && 
            inputFileChannel 	!= null ){ 
 		 
	
	    AlignReadsToRefBwaMem2  ( ref_gen_channel, indexes.collect(),READS )		   	
	    AssignReadGroup	    ( AlignReadsToRefBwaMem2.out )
	    MarkDuplicates	    ( AssignReadGroup.out )
	    IndexBam		    ( MarkDuplicates.out.sorted_markduplicates_bam )
	    BamCoverage             ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out),bedtarget )  
	    
	    if (params.report ) {
	    	GenerateStat	    ( AssignReadGroup.out.sorted_labeled_bam, MarkDuplicates.out.sorted_markduplicates_bam) 
		BigWig		    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) )
	    	BigWigCoveragePlots ( BigWig.out, params.mindepth, params.saveImg)
		AlignmentMetrics    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel )
	        InsertMetrics	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
	        GcBiasMetrics	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out) , ref_gen_channel ) 
	        Qualimap	    ( MarkDuplicates.out.sorted_markduplicates_bam.join(IndexBam.out)  )
       
	    } 
        } else {        
            error("\033[31m Error: Invalid or missing parameters.\n\n" +
	    	  "\033[31m Please specify valid parameters:\n\n" +
	    	  " --reference option ( --reference <reference-path> )\n\n" +
	    	  " --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n\n" +
	    	  " --aligner bwamem2 , Default bwa ( not to be mentionned )\n\n" +
	    	  " --report , To Generate Bam Metrics \n\n"+
	    	  "------------------------------------------------------------\n\n" +
	    	  " For more information:\n\n" +
	    	  "   >>  View the help menu: nextflow main.nf --help\n\n" +
	    	  "   >>  Check parameters: nextflow main.nf --params\n\n \033[37m")  
        }

    } else {  
        error("\033[31m Error: Invalid or missing parameters.\n\n" +
              " Please specify valid parameters:\n\n" +
              " --reference option ( --reference <reference-path> )\n\n" +
              " --tobealigned ( --tobealigned CSVs/3_samplesheetForAssembly.csv )\n\n" +
              " --aligner bwamem2 , Default bwa ( not to be mentionned )\n\n" +
              " --report , To Generate Bam Metrics \n\n"+
              "------------------------------------------------------------\n\n" +
              " For more information:\n\n" +
              "   >>  View the help menu: nextflow main.nf --help\n\n" +
              "   >>  Check parameters: nextflow main.nf --params\n\n \033[37m") 
    }	
    emit : 
    bams = MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }
    bamIdx = IndexBam.out
    bamWithIdx = ( MarkDuplicates.out.sorted_markduplicates_bam.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }).join(IndexBam.out)

}
