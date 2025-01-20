// Raw Quality Control subworkflow 

include { DelMoroWelcome	} from '../../logos'	
include { DelMoroRAWQCOutput	} from '../../logos'	

include { FastqQc		} from '../../modules/1_RawReadsQualCtrl.nf' 
include { ReadsMultiqc		} from '../../modules/1_RawReadsQualCtrl.nf' 

workflow QC_RAW_READS {
   take:
      rawReads
    
   main: 
      if ( params.exec 		!= null && 
      	   params.rawreads 	!= null){
     	   DelMoroRAWQCOutput() 
     	   FastqQc( rawReads )	
	   ReadsMultiqc	( FastqQc.out.collect()  )
     
      } else { 
	  
	  DelMoroWelcome() 
	  
	  print("\033[31m Please specify valid parameters:\n"					)
   	  print("\033[31m  --rawreads option (--rawreads CSVs/1_samplesheetForRawQC.csv ) \n"	)  
 	  print("For details, run: nextflow main.nf --exec params\n\033[37m"			)
   }  
}
