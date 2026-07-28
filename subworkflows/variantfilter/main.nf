// Variant Filtering subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroFiltOutput	} from '../../.logos'
	
include { SNPSelect		} from '../../modules/09.0_filter.nf' 
include { FilterSNP		} from '../../modules/09.0_filter.nf' 
include { INDELSelect		} from '../../modules/09.0_filter.nf' 
include { FilterINDEL		} from '../../modules/09.0_filter.nf'
include { SortVCF as SortSnpVcf	} from '../../modules/09.0_filter.nf' 
include { SortVCF as SortIndVcf	} from '../../modules/09.0_filter.nf' 
include { mergeVCFs		} from '../../modules/09.0_filter.nf' 

workflow FILTER_VARIANT {

    take:
    vcf

    main: 
    if (params.stepmode && params.exec == "filter") { DelMoroFiltOutput() }
    
    def hasVcfInput = params.fullmode ? true : (params.tofilter != null)
    
    if (hasVcfInput) {     
      SNPSelect     (vcf)
      FilterSNP     (SNPSelect.out  )
      INDELSelect   (vcf)
      FilterINDEL   (INDELSelect.out )  
      SortSnpVcf    (FilterSNP.out)
      SortIndVcf    (FilterINDEL.out)
      mergeVCFs     (SortSnpVcf.out.join(SortIndVcf.out).map { sampleId, snpVcf, snpIdx, indelVcf, indelIdx -> tuple(sampleId, snpVcf, snpIdx, indelVcf, indelIdx) } )
    
    } else { 
	print("\033[31m Error: Invalid or missing parameters.\n" )
	print(" Please specify valid parameters:\n"              )
	print(" --tofilter option (--tofilter CSVs/5_samplesheetVcfbFiles.csv )\n "  )
	print(" --keepinter [option]  : to keep intermediate vcf files"    ) 
        print(" ---------------------------------------------------------------------------\n"  )
        print(" For more information:\n"                                        )
        print("   >>  View the help menu: nextflow main.nf --help\n"            )
        print("   >>  Check parameters: nextflow main.nf --params\n\033[37m"    ) 
    } 
}


