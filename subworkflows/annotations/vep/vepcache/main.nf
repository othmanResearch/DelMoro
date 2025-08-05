// Ensembl-vep Downloading cache 

include { DelMoroWelcome	} from '../../../../.logos'
include { DelMoroVepCache	} from '../../../../.logos'
	
include { DownloadVepCache	} from '../../../../modules/7_VepCacheDownload.nf'  

workflow VEP_CACHE {
    take:
    species
    assembly
    cachetype
    cachedir
    cacheversion

    main:
    
    if ( !params.species ){
    
	DelMoroWelcome()
	print("\033[31m Please specify valid parameters:\n" )
	print("\033[31m  --species   parameter ( For more info please check https://ftp.ensembl.org/pub/release-114/variation/indexed_vep_cache/ )\n") 
	print("\033[31m  --cachetype parameter [ optional ] \n") 
	print("\033[31m  --assembly  parameter [ optional ] \n") 
	print("\033[31m  --cacheversion  parameter [ optional ] \n") 
	print(" For details, run: nextflow main.nf --exec params\n\033[37m" )
    
    } else if (params.species 	&& 
       	    params.cachetype	&& 
 	    !(cachetype in ['refseq', 'merged']) ){

	DelMoroWelcome()
	println("\033[31m ❌ Invalid cachetype: '${cachetype}'")
	println("\033[31m    --cachetype must be one of: refseq, merged\n\033[37m")
 
    } else {

	DelMoroVepCache()
	DownloadVepCache(species, assembly, cachetype, cachedir, cacheversion) 
    } 
}


 
