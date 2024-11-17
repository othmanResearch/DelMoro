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
    		print("\033[31m Please specify valid parameters:\n")
    		print("  --basedon option ( --basedon CSVs/1_samplesheetForRawQC.csv )\n")
  		print("For details, run: nextflow main.nf --exec params\n\033[37m")
		}
	}
  /*emit:
  */
}
