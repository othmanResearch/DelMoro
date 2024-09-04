// Module files for DelMoro pipeline

// indexing known sites files 

process IndexKNownSites {
    	conda "bioconda::gatk4=4.4"
    	tag "CREATING INDEX for known sites vcf"
    	publishDir "${params.outdir}/Indexes/knownSites", mode: 'copy'

    	input:
        	path kn_site_File1 	  // known Sites file n°1 related to params.knwonSite1
        	path kn_site_File2 	  // known Sites file n°2 related to params.knwonSite2

    	output:
        	path "${kn_site_File1}.idx"	, emit: "IDXknS1" 
        	path "${kn_site_File2}.idx"     , emit: "IDXknS2"
    
    	script:
        """
        gatk IndexFeatureFile \\
        		--input ${kn_site_File1} \\
        		--output ${kn_site_File1}.idx 
        
       	gatk IndexFeatureFile \\
        		--input ${kn_site_File2} \\
        		--output ${kn_site_File2}.idx 
       	"""
}
