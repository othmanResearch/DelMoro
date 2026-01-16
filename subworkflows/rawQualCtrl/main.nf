// Raw Quality Control subworkflow 

include { DelMoroWelcome	} from '../../.logos'	
include { DelMoroRAWQCOutput	} from '../../.logos'	

include { FastqQc		} from '../../modules/01.0_RawReadsQualCtrl.nf' 
include { ReadsMultiqc		} from '../../modules/01.0_RawReadsQualCtrl.nf' 

workflow QC_RAW_READS {
    take:
	rawReads
    
    main: 
    if (params.stepmode && params.exec == "rawqc" ) { DelMoroRAWQCOutput() }
    if ( params.rawreads != null ){
    
	FastqQc	( rawReads )	
	ReadsMultiqc( FastqQc.out.collect()  )
     
    } else { 
        print("\033[31m Error: Invalid or missing parameters.\n"                        )
        print(" Please specify valid parameters:\n"					)
	print(" --rawreads option (--rawreads CSVs/1_samplesheetForRawQC.csv ) \n"	)
	print(" --------------------------------------------------------------\n"       )
	print(" For more information:\n"                                                )
        print("   >>  View the help menu: nextflow main.nf --help\n"			)
	print("   >>  Check parameters: nextflow main.nf --params\n\033[37m"		)
   }  
}

