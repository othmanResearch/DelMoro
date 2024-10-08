// Generate CSVs subworkflow 

include {DelMoroWelcome; PATHTOCSV}		from '../../logos'	
include {WriteCSV}		from '../../modules/0_GenerateCSVs.nf' 


workflow GenerateCSVs {
  
  take:
    	input
    
  main: 
    if ( params.generate == 'CSV' )   {
  	   if(params.basedon != null) {
     	      PATHTOCSV()
     	      WriteCSV(input) 
     	      } else { 
     	      DelMoroWelcome()
     	      print("\033[31m please specify --basedon option (--basedon CSV FILE) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
	}
	
  /*emit:
  */

}
 
