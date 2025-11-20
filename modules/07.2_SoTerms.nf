// Module files for DelMoro pipeline

// Extract vcf's sequences ontologies 

process ExtractImpactVariant {
    tag "${fileName} - ${term} (${impact})"
    publishDir "outdir/annotation/seqOnto/${fileName}/${impact}/", mode: 'copy'

    input:
    tuple val(fileName), val(term), val(impact), path(vcf_file)

    output:
    path "${fileName}_${term}.vcf.gz"

    script:
    """
    zgrep -E "^#|${term}" ${vcf_file} | bgzip -c > ${fileName}_${term}.vcf.gz
    """
}
