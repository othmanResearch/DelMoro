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
    	print("\033[31m Please specify valid parameters:\n")
  	print("\033[31m  --knwonSite1 option ( --knwonSite1 knownsites/file1.vcf ) \n")
  	print("\033[31m  and \n")
  	print("\033[31m  --knwonSite2 option ( --knwonSite2 knownsites/file2.vcf ) \n")
    	print("For details, run: nextflow main.nf --exec params\n\033[37m")
    	}
  /*emit:
  */

}
