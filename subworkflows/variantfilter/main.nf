// Variant Calling subworkflow 

include { DelMoroWelcome	} from '../../.logos'
include { DelMoroVarCallOutput	} from '../../.logos'
	

include { IndexVcf                    } from '../../modules/11_filter.nf' 
include { IndexVcf  as IndexSNPVcf    } from '../../modules/11_filter.nf' 
include { IndexVcf  as IndexINDELVcf  } from '../../modules/11_filter.nf' 
include { SNPSelect		} from '../../modules/11_filter.nf' 
include { FilterSNP		} from '../../modules/11_filter.nf' 
include { INDELSelect		} from '../../modules/11_filter.nf' 
include { FilterINDEL		} from '../../modules/11_filter.nf' 

workflow FILTER_VARIANT {

    take:
    vcf

 
    main: 
    if (params.stepmode && params.exec == "filter" ) {     
      IndexVcf      (vcf)
      SNPSelect     (vcf.join(IndexVcf.out) )
      FilterSNP     (SNPSelect.out  )
      INDELSelect   (vcf.join(IndexVcf.out) )
      FilterINDEL   (INDELSelect.out )  
    }
}


