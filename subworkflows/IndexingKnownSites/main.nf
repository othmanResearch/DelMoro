// Index KnownSite VCD subworkflow 


include {DelMoroIDXKNSITESOutput} from '../../logos'	
include {IndexKNownSites} from '../../modules/3_KnownSitesIndexing.nf' 


workflow INDEXING_known_sites {
take:
    knwonSite1
    knwonSite2
 
  main: 
   DelMoroIDXKNSITESOutput()
   IndexKNownSites (knwonSite1,knwonSite2)     

  /*emit:
  */

}


	
