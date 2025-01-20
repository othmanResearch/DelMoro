// Trimming subworkflow 

include { DelMoroWelcome	} from '../../logos'	
include { DelMoroTRimmOutput	} from '../../logos'	

include { Trimming		} from '../../modules/2_Trimming.nf' 
include { TrimmedQC 		} from '../../modules/2_Trimming.nf' 
include { MultiqcTrimmed	} from '../../modules/2_Trimming.nf' 

workflow TRIM_READS {
   take:
     rawReads
    
   main: 
  	if ( params.exec 	!= null && 
  	     params.tobetrimmed != null ){
  	     
  	     DelMoroTRimmOutput()
       	   
       	     Trimming		( rawReads 		  )			   	
	     TrimmedQC		( Trimming.out.paired     )              
	     MultiqcTrimmed	( TrimmedQC.out.collect() )
             
             } else { 
	    
	      DelMoroWelcome() 
	      print("\033[31m Please specify valid parameters:\n"					  )
	      print("\033[31m  --tobetrimmed option (--tobetrimmed CSVs/2_SamplesheetForTrimming.csv ) \n")  
    	      print("For details, run: nextflow main.nf --exec params\n\033[37m"			  )
     } 
}

 
