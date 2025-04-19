// Module files for DelMoro pipeline

// Vep Cache Download 

process DownloadVepCache {
    tag "DOWNLOAD VEP CACHE FOR ${species}"
    publishDir "./", mode: 'copy'

    conda 'bioconda::ensembl-vep=113.4'
    container "${workflow.containerEngine == 'singularity' 	?
    		'docker://iarcbioinfo/ensembl-vep' 		: 
    		'iarcbioinfo/ensembl-vep'	}"

    input:
    val species
    val assembly
    val cachetype
    val cachedir

    output:
    path "${cachedir}"

    script:
    def speciesArg = params.cachetype ? "--SPECIES ${params.species}_${params.cachetype}" : "--SPECIES ${params.species}"
    def assemblyArg = params.assembly ? "--ASSEMBLY ${params.assembly}" : ""

    """
    vep_install \
        --AUTO c \
        ${speciesArg} \
        ${assemblyArg} \
        --CACHE_DIR ${cachedir}
    """
}






