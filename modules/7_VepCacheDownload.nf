// Module files for DelMoro pipeline

// Vep Cache Download 

process DownloadVepCache {
    tag "DOWNLOAD VEP CACHE FOR ${species}"
    publishDir "./", mode: 'copy'

    conda 'bioconda::ensembl-vep=114.2'
    container "${workflow.containerEngine == 'singularity'
        ? 'docker://ensemblorg/ensembl-vep:latest'
        : 'ensemblorg/ensembl-vep:latest'}"

    input:
    val species
    val assembly
    val cachetype
    val cachedir
    val cacheversion

    output:
    path "${cachedir}"

    script:
    def installerCmd = System.getenv('CONDA_PREFIX') != null ? "vep_install" : "INSTALL.pl"
    def speciesArg = params.cachetype ? "--SPECIES ${params.species}_${params.cachetype}" : "--SPECIES ${params.species}"
    def assemblyArg = params.assembly ? "--ASSEMBLY ${params.assembly}" : ""
    def cacheVersionArg = cacheversion ? "--CACHE_VERSION ${cacheversion}" : "--NO_UPDATE"

    """
    ${installerCmd} \\
    --AUTO c \\
    ${speciesArg} \\
    ${assemblyArg} \\
    --CACHE_DIR ${cachedir} \\
    ${cacheVersionArg}
    """
}
