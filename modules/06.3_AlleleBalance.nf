// Module files for DelMoro pipeline

// ADD ALLELE BALANCE

process AlleleBalance {
    tag "ADD ALLELE BALANCE RaTIO FOR ${vcf}."
    publishDir "${params.outdir}/Variants/${params.caller ? "deepvariant" : "gatk" }", mode: 'copy', enabled: params.rsid == null

    conda "bioconda::bcftools=1.21"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/bcftools:1.21"
        : "firaszemzem/bcftools:1.21"}"
        
    input:
    tuple val(patient_id), path(vcf), path(vcfIdx)

    output:
    tuple val(patient_id), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz"), 
        path("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz.{tbi,idx}")

    script:
    """
    python3 << 'PYSCRIPT'
	import pysam

	vcf = pysam.VariantFile("${vcf}")
	vcf.header.formats.add('AB', '1', 'Float', 
		'Allele balance: AD[ALT]/(AD[REF]+AD[ALT])')

	out_vcf = pysam.VariantFile("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz", 'wz', header=vcf.header)

	for record in vcf:
		if 'AD' in record.format:
		    for sample in record.samples:
		        ad = record.samples[sample].get('AD')
		        if ad is not None:
		            try:
		                ref = int(ad[0]) if ad[0] is not None else 0
		                alt = sum([int(x) for x in ad[1:] if x is not None])
		                total = ref + alt
		                record.samples[sample]['AB'] = round(alt / total, 4) if total > 0 else None
		            except (TypeError, ValueError, IndexError):
		                record.samples[sample]['AB'] = None
		        else:
		            record.samples[sample]['AB'] = None
		
		out_vcf.write(record)

	vcf.close()
	out_vcf.close()
	pysam.tabix_index("${vcf.getBaseName(vcf.name.endsWith('.gz')? 2: 1)}.AB.vcf.gz", preset='vcf', force=True)
	PYSCRIPT
    """
}

