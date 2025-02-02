// Generate CSVs subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { PATHTOCSV		} from '../../.logos'	
	
include { WriteTrimmingCSV	} from '../../modules/0_GenerateCSVs.nf' 
include { WriteAssemblyCSV	} from '../../modules/0_GenerateCSVs.nf' 
include { WriteBamCSV 		} from '../../modules/0_GenerateCSVs.nf' 
include { WriteRecalCSV		} from '../../modules/0_GenerateCSVs.nf' 

workflow GenerateCSVs {
    take:
	input
   
    main: 
    if ( params.generate == 'CSV' ) {
	if ( params.basedon != null) {
	     
	     PATHTOCSV()
     	     
     	     WriteTrimmingCSV(input) 
     	     WriteAssemblyCSV(input)
     	     WriteBamCSV(input)
     	     WriteRecalCSV(input)
     	      
     	    } else { 
     	     	DelMoroWelcome()
    		print("\033[31m Please specify valid parameters:\n")
    		print("  --basedon option ( --basedon CSVs/1_samplesheetForRawQC.csv )\n")
  		print("For details, run: nextflow main.nf --exec params\n\033[37m")
  	}
    } 
}
