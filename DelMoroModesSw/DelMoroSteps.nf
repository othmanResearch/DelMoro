#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// params 

// Interactive Design while Running DelMoro

include {DelMoroWelcome		}    from '../.logos' 
include {DelMoroParams		}    from '../.logos' 
include {DelMoroVersion		}    from '../.logos' 
include {DelMoroHelp		}    from '../.logos' 
include {DelMoroError		}    from '../.logos' 
include {DelMoroAnnotateHelp	}    from '../.logos' 

// subworkflows 
include { GENERATE_CSVS		} from '../subworkflows/generateCSV'
include { QC_RAW_READS		} from '../subworkflows/rawQualCtrl'
include { TRIM_READS		} from '../subworkflows/trimming'
include { INDEXING_REF_GENOME	} from '../subworkflows/indexingRefGenome'
include { ALIGN_TO_REF_GENOME	} from '../subworkflows/mapping'
include { BASE_QU_SCO_RECA	} from '../subworkflows/bqsr'
include { CALL_SNPs_GATK	} from '../subworkflows/variantcalling'
include { VEP_CACHE		} from '../subworkflows/annotations/vep/vepcache'
include { VEP_ANNOTATE		} from '../subworkflows/annotations/vep/vepannotate'
include { REPORTING		} from '../subworkflows/reporting/main.nf' 


workflow DelMoroSteps {

    take: 
    PrepareCsv
    RawReads
    ReadsToBeTrimmed
    RefGenChannel
    AlignIdxRef
    ReadsToBeAligned
    Target
    DictIdxRef
    SamtIdxRef
    MappedReads
    IdxBam
    KnownSite1
    KnownSite2
    ToVarCall
    VepSpecies 
    Assembly
    CacheType
    CacheDir
    CacheVersion
    VcfChannel
    CacheDirANN
    metaPipeExecYaml
   
    main: 
    
    params.exec = null  // Default to 'none' if not provided
  
    if (params.exec == null ){
    
    DelMoroWelcome()   
    GENERATE_CSVS(PrepareCsv)
  
    } else if (params.exec == 'rawqc') {    // check quality of raw reads
 
    QC_RAW_READS(RawReads)  
        
    } else if (params.exec == 'trim') {        // trim reads

    TRIM_READS(ReadsToBeTrimmed)  
    
    } else if (params.exec == 'refidx') {    // generate index for reference genome    

    INDEXING_REF_GENOME(RefGenChannel) 
 
    } else if (params.exec == 'align') {    // align reads to reference

    ALIGN_TO_REF_GENOME(RefGenChannel,AlignIdxRef,ReadsToBeAligned,Target) 
     
    } else if (params.exec == 'bqsr') {
           
    BASE_QU_SCO_RECA(RefGenChannel,DictIdxRef,SamtIdxRef,MappedReads,IdxBam,KnownSite1,KnownSite2 )
               
    } else if (params.exec == 'callsnp') {    // Call snp
              
    CALL_SNPs_GATK(RefGenChannel,DictIdxRef,SamtIdxRef,ToVarCall,IdxBam) 
          
    } else if ( params.exec == 'annotate' ) {

    DelMoroAnnotateHelp()
               
    } else if ( params.exec == 'vepcache' ) {
              
    VEP_CACHE(VepSpecies,Assembly,CacheType,CacheDir,CacheVersion)
               
    } else if ( params.exec == 'vepannotate' ) {
              
    VEP_ANNOTATE(VcfChannel,RefGenChannel,SamtIdxRef,CacheDirANN,VepSpecies,Assembly,CacheType,CacheVersion)
               
    } else if (params.exec == 'reporting') {
  	              
    REPORTING(metaPipeExecYaml)
  	              	
    } else if ( params.exec == 'help'){
             
    DelMoroHelp()
            
    } else if ( params.exec == 'params' ) {
                     
    DelMoroParams()
                
    } else if ( params.exec == 'version' ) {
                
    DelMoroVersion()

    } else { DelMoroError() }
   
 }
       


