include {Trimming; TrimmedQC; MultiqcTrimmed} from '../../modules/2_Trimming.nf' 


workflow TRIM_READS {
  
  take:
    	rawReads
    
  main: 
     	Trimming	( rawReads )	
			   	
	TrimmedQC	( Trimming.out.paired  )
                      
	MultiqcTrimmed	( TrimmedQC.out.collect() )
         		
     	
  /*emit:
  */

}


	
