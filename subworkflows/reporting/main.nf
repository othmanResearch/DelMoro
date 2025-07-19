// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroReporting	} from '../../.logos'
	
include { generateReports	} from '../../modules/10_reporting.nf'
 
workflow REPORTING {

    take:
	patInfoVcfLogoMeta
    
    main:  
 
    
	if (params.delmoroLogo 	&&
	    params.metaPatients &&
	    params.metaYaml )  {
	    
	 DelMoroReporting()
	 generateReports(patInfoVcfLogoMeta)
 
 	}  else { 
	    DelMoroWelcome() 
	    print("\033[31m Please specify valid parameters:\n"			)
	    print(" --metaPatients option (--metaPatients CSVs/7_metaPatients.csv ) \n"	)
	    print(" --metaYaml option (--metaYaml CSVs/7_metaPatients.yml)\n "		)
	} 
}



 

 
	    
	    
	
