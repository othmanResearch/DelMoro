// Index KnownSite VCD subworkflow 


include {DelMoroWelcome; DelMoroIDXKNSITESOutput} from '../../logos'	
include {IndexKNownSites} from '../../modules/3_KnownSitesIndexing.nf' 


workflow INDEXING_known_sites {
take:
    knwonSite1
    knwonSite2
 
  main: 
   if (params.exec != null && params.knwonSite1 != null && params.knwonSite2 != null) {
      DelMoroIDXKNSITESOutput()
      IndexKNownSites (knwonSite1,knwonSite2)     
      } else { 
	    DelMoroWelcome() 
	    print("\033[31m please specify --knwonSite1 and --knwonSite2 options (for knwons sites to be indexed ) \n For more details nextflow main.nf --exec ShowParams \033[37m")  }
  /*emit:
  */

}


	
