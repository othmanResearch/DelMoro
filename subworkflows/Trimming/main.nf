// Trimming subworkflow 

include {DelMoroWelcome; DelMoroTRimmOutput} from '../../logos'	
include {Trimming; TrimmedQC; MultiqcTrimmed} from '../../modules/2_Trimming.nf' 


workflow TRIM_READS {
  
  take:
    	rawReads
    
  main: 
  	if (params.exec != null && params.ToBeTrimmed != null) {
  	   DelMoroTRimmOutput()
       	   Trimming		( rawReads )			   	
	   TrimmedQC		( Trimming.out.paired  )              
	   MultiqcTrimmed	( TrimmedQC.out.collect() )
	   } else { 
	    DelMoroWelcome() 
	    print("\033[31m please specify --ToBeTrimmed option (--ToBeTrimmed CSV ) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
       
       
         		
     	
  /*emit:
  */

}

 
