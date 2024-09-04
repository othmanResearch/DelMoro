include {FastqQc; ReadsMultiqc} from '../../modules/1_RawReadsQualCtrl.nf' 


workflow QC_RAW_READS {
  
  take:
    	rawReads
    
  main: 
     	FastqQc	( rawReads )	
			   	
	ReadsMultiqc	( FastqQc.out.collect()  )
       
       
  /*emit:
  */

}


	
