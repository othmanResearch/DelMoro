// Ensembl-vep Annotation 

include { DelMoroWelcome	} from '../../../../.logos'
include { DelMoroVepAnnot	} from '../../../../.logos'  
	
include { VepAnnotation		} from '../../../../modules/8_vepAnnotate.nf'  

workflow VEP_ANNOTATE {
    take:
    	vcf
	fasta
	genomeindex
	vepcache
	species
	assembly
	cachetype

    main:
    if ( params.species &&
    	 params.reference &&
    	 params.assembly &&
    	 params.toannotate &&
     	(!params.cachetype || params.cachetype == 'refseq' || params.cachetype == 'merged' ) ) {

   	 DelMoroVepAnnot()
   	 VepAnnotation(vcf, fasta, genomeindex, vepcache, species, assembly, cachetype)

	} else {

	    DelMoroWelcome()
	    print("\033[31m Please specify valid parameters:\n")
	    print("\033[31m --species option (e.g. --species homo_sapiens )\n")
	    print("\033[31m --reference option ( --reference <reference-path> ), For more info: https://ftp.ensembl.org/pub/release-113/variation/indexed_vep_cache/\n")
	    print("\033[31m --assembly option (e.g. --assembly GRCh37 )\n")
	    print("\033[31m --toannotate option (e.g. --vcftoannotate <path-to-vcf> )\n")
	    print("\033[31m Optional: --cachetype must be one of: refseq, merged\n")
	    print(" For details, run: nextflow main.nf --exec params\n\033[37m")

	}

}



 
