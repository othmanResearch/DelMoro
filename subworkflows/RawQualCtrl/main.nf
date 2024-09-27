// Raw Quality Control subworkflow 

include {DelMoroRAWQCOutput} from '../../logos'	
include {FastqQc; ReadsMultiqc} from '../../modules/1_RawReadsQualCtrl.nf' 


workflow QC_RAW_READS {
  
  take:
    	rawReads
    
  main: 
  	DelMoroRAWQCOutput() 
  	
     	FastqQc	( rawReads )	
			   	
	ReadsMultiqc	( FastqQc.out.collect()  )
       
       
  /*emit:
  */

}


	
