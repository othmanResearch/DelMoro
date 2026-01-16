// Trimming subworkflow 

include { DelMoroWelcome	} from '../../.logos'	
include { DelMoroTRimmOutput	} from '../../.logos'	

include { Trimmomatic		} from '../../modules/02.0_Trimming.nf' 
include { Fastp			} from '../../modules/02.0_Trimming.nf'  
include { Bbduk			} from '../../modules/02.0_Trimming.nf' 
include { TrimmedQC 		} from '../../modules/02.0_Trimming.nf' 
include { MultiqcTrimmed	} from '../../modules/02.0_Trimming.nf' 

workflow TRIM_READS {
    take:
    rawReads
    
    main: 
    if (params.stepmode && params.exec == "trim" ) { DelMoroTRimmOutput() }
    if ( params.tobetrimmed != null && params.trimmomatic) {
	       	   
	Trimmomatic	( rawReads 		  )			   	
	TrimmedQC	( Trimmomatic.out.paired  )	              
	MultiqcTrimmed	( TrimmedQC.out.collect() )
	     
	emit: 
	trimmedReads = Trimmomatic.out.paired.collect()
	trimmedQc    = TrimmedQC.out.collect()
	multiQcccc   = MultiqcTrimmed.out.multiqcHtml.collect() 	
    
    } else if (params.tobetrimmed != null && params.fastp) {
	Fastp		( rawReads.map { patient_id, R1, R2, MINLEN, LEADING, TRAILING, SLIDINGWINDOW -> [patient_id, R1, R2] } ) 			   	
	TrimmedQC	( Fastp.out.fastpFastq )	              
	MultiqcTrimmed	( TrimmedQC.out.collect() )
	    
	emit : 
	trimmedReads = Fastp.out.fastpFastq.collect()
	trimmedQc    = TrimmedQC.out.collect()
	multiQcccc   = MultiqcTrimmed.out.multiqcHtml.collect()
    
    } else if (params.tobetrimmed != null && params.bbduk) {

	Bbduk		( rawReads.map { patient_id, R1, R2, MINLEN, LEADING, TRAILING, SLIDINGWINDOW -> [patient_id, R1, R2] } ) 			   	
	TrimmedQC 	( Bbduk.out.bbdukFastq )	              
	MultiqcTrimmed	( TrimmedQC.out.collect() )
  
	emit : 
	trimmedReads = Bbduk.out.bbdukFastq.collect()
	trimmedQc    = TrimmedQC.out.collect()
	multiQcccc   = MultiqcTrimmed.out.multiqcHtml.collect()
    
    }else { 
	print("\033[31m Error: Invalid or missing parameters.\n"                                        )
	print("\033[31m Please specify valid parameters:\n"					  	)
	print("\033[31m  --tobetrimmed option (--tobetrimmed CSVs/2_SamplesheetForTrimming.csv )\n"	) 
	print("\033[31m Please specify Trimming parameters: --trimmomatic , --fastp or --bbduk \n"	)				   
        print(" ----------------------------------------------------------------------\n"               )
	print(" For more information:\n"                                                )
        print("   >>  View the help menu: nextflow main.nf --help\n"			)
	print("   >>  Check parameters: nextflow main.nf --params\n\033[37m"		)  
    }
} 





        
