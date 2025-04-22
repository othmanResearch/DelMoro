// Module files for DelMoro pipeline

// Vep Cache Download 
 

process VepAnnotation {
    tag "ANNOTATE ${vcf} WITH VEP"
    publishDir "${params.outdir}/annotation/", mode: 'copy'
    
    conda 'bioconda::ensembl-vep=113.4'
    container "${workflow.containerEngine == 'singularity' 	?
    		'docker://iarcbioinfo/ensembl-vep' 		: 
    		'iarcbioinfo/ensembl-vep'	}"

    input:
	tuple val(patient_id), path(vcf)
	path fasta
	path genomeindex
	val cachedir
	val species
	val assembly
	val cachetype


    output:
	path "*.vcf.gz"		, emit: vcf
	path "*.html"		, emit: report
	path "*.vcf.gz.tbi"	, emit: tbi

    script:
    // Set cache flags using ternary operator
    def cachetypeArg = cachetype ? "--${cachetype}" : ""
    
    """
    vep \\
        --input_file ${vcf} \\
        --output_file ${vcf.simpleName}_vep.vcf.gz \\
        --format vcf \\
        --vcf \\
        --species ${species} \\
        --cache \\
        --dir_cache ${cachedir} \\
        --fasta ${fasta} \\
        --offline \\
        --assembly ${assembly} \\
        --stats_file ${vcf.simpleName}_vep.html \\
        --force_overwrite \\
        --compress_output bgzip \\
        --fork ${task.cpus} \\
        ${cachetypeArg}
        
    tabix -p vcf ${vcf.simpleName}_vep.vcf.gz
    """
}
 
 
