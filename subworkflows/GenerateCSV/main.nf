// Generate CSVs subworkflow 

include {PATHTOCSV}		from '../../logos'	
include {WriteCSV}		from '../../modules/0_GenerateCSVs.nf' 


workflow GenerateCSVs {
  
  take:
    	input
    
  main: 
  	if ( params.generate == 'CSV') {
	PATHTOCSV()
     	WriteCSV(input)
     	}
       
       
  /*emit:
  */

}


	
