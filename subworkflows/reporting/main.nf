// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroReporting	} from '../../.logos'

include { ReportBamCov          } from '../../modules/08.0_Reporting.nf'
include { GenerateReports	} from '../../modules/08.0_Reporting.nf'
 
workflow REPORTING {

    take:
    patInfoVcfLogoMeta
    bedtarget
    
    main:  
    if (params.delmoroLogo 	&&
    	params.metaPatients &&
    	params.metaYaml )  {
	    
    	DelMoroReporting()
    	// Define channel for BamCoverage & check bam Index 
        bamCoverageCh = patInfoVcfLogoMeta
            .map { metaPatients, bamFile, vcFile, delmoroLogo, pipeExecYaml_Ch ->
                def bam = file(bamFile)
                def indexPath = "${bam}.bai"
                def indexFile = file(indexPath)
                if (!indexFile.exists()) {
                    log.warn "Index file missing for BAM: ${bam}. Expected: ${indexPath}"
                    return null
                } 
                tuple(metaPatients.Identifier, bam, indexFile)
                }.filter { it != null }
                
        ReportBamCov(bamCoverageCh,bedtarget)
        //ReportBamCov.out.view()

        bedCombiedCh = ReportBamCov.out.join(patInfoVcfLogoMeta.map { metadata, bamFile, vcFile, delmoroLogo, pipeExecYaml_Ch -> tuple( metadata.Identifier, metadata, bamFile, vcFile, delmoroLogo, pipeExecYaml_Ch ) } ) .map { patient_id, coverageBed, metadata, bamFile, vcFile, delmoroLogo, pipeExecYaml_Ch -> tuple( metadata, vcFile, delmoroLogo, pipeExecYaml_Ch, coverageBed ) }
        
        
        //bedCombiedCh.view()
        GenerateReports(bedCombiedCh,bedtarget)
 
    } else { 
   	DelMoroWelcome() 
	print("\033[31m Please specify valid parameters:\n"			)
	print(" --metaPatients option (--metaPatients CSVs/7_metaPatients.csv ) \n"	)
	print(" --metaYaml option (--metaYaml CSVs/7_metaPatients.yml)\n "		)
    } 
}



 

 
	    
	    
	
