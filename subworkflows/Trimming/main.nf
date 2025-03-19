// Trimming subworkflow 

include { DelMoroWelcome	} from '../../.logos'	
include { DelMoroTRimmOutput	} from '../../.logos'	

include { Trimmomatic		} from '../../modules/2_Trimming.nf' 
include { Fastp			} from '../../modules/2_Trimming.nf'  
include { Bbduk			} from '../../modules/2_Trimming.nf' 
include { TrimmedQC 		} from '../../modules/2_Trimming.nf' 
include { MultiqcTrimmed	} from '../../modules/2_Trimming.nf' 

workflow TRIM_READS {
    take:
	rawReads
    
    main: 
    if ( params.tobetrimmed != null && params.trimmomatic) {
  	 
  	 DelMoroTRimmOutput()
	       	   
 	 Trimmomatic	( rawReads 		  )			   	
	 TrimmedQC	( Trimmomatic.out.paired 	  )	              
	 MultiqcTrimmed	( TrimmedQC.out.collect() )
	     
	} else if (params.tobetrimmed != null && params.fastp) {
		 
	    DelMoroTRimmOutput()
	       	   
	    Fastp		( rawReads.map { patient_id, R1, R2, MINLEN, LEADING, TRAILING, SLIDINGWINDOW -> [patient_id, R1, R2] } ) 			   	
	    TrimmedQC		( Fastp.out.fastpFastq )	              
	    MultiqcTrimmed	( TrimmedQC.out.collect() )
 
	    } else if (params.tobetrimmed != null && params.bbduk) {
		 
	    	DelMoroTRimmOutput()
	       	   
 		Bbduk		( rawReads.map { patient_id, R1, R2, MINLEN, LEADING, TRAILING, SLIDINGWINDOW -> [patient_id, R1, R2] } ) 			   	
	    	TrimmedQC 	( Bbduk.out.bbdukFastq )	              
	    	MultiqcTrimmed	( TrimmedQC.out.collect() )
  

    
    }else { 
			    
	DelMoroWelcome() 
	print("\033[31m Please specify valid parameters:\n"					  	)
	print("\033[31m  --tobetrimmed option (--tobetrimmed CSVs/2_SamplesheetForTrimming.csv )\n"	) 
	print("\033[31m Please specify Trimming parameters: --trimmomatic , --fastp or --bbduk \n"	)				   
	print(" For details, run: nextflow main.nf --exec params\n\033[37m"			  	)
    } 	
} 


