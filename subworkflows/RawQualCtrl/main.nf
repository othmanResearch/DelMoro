// Raw Quality Control subworkflow 

include {DelMoroWelcome; DelMoroRAWQCOutput} from '../../logos'	
include {FastqQc; ReadsMultiqc} from '../../modules/1_RawReadsQualCtrl.nf' 


workflow QC_RAW_READS {
  
  take:
    	rawReads
    
  main: 
  	if (params.exec != null && params.RawReads != null) {
     	   DelMoroRAWQCOutput() 
     	   FastqQc( rawReads )	
	   ReadsMultiqc	( FastqQc.out.collect()  )
	   } else { 
	    DelMoroWelcome() 
	    print("\033[31m please specify --RawReads option (--RawReads CSV ) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
       
       
  /*emit:
  */

}


	
