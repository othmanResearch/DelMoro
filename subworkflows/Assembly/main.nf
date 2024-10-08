// Assembly subworkflow 

include {DelMoroWelcome; DelMoroAssemblyOutput} from '../../logos'	
include {alignReadsToRef; assignReadGroup; markDuplicates; IndexBam; GenerateStat} from '../../modules/4_Assembly.nf' 


workflow ALIGN_TO_REF_GENOME {
take:
    ref_gen_channel
    indexes
    READS
  main: 
    if (params.exec != null && params.refGenome != null && params.ToBeAligned != null ) {
 	DelMoroAssemblyOutput()
        alignReadsToRef	(ref_gen_channel, indexes.collect(),READS )	
			   	
	assignReadGroup	(alignReadsToRef.out.collectFile(sort: true))
                      
	markDuplicates	(assignReadGroup.out.collectFile( sort: true))
         		
     	IndexBam	(markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)   	
         	     	
	GenerateStat	(assignReadGroup.out.sorted_labeled_bam.collectFile(sort: true), markDuplicates.out.sorted_markduplicates_bam.collectFile(sort: true)	)
} else { 
	    DelMoroWelcome() 
	    print("\033[31m please specify --refGenome option (--refGenome reference ) and --ToBeAligned option (--ToBeAligned trimmedreads ) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
       



  /*emit:
  */

}


	
	
