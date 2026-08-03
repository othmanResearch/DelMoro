// Ensembl-vep Annotation 

include { DelMoroWelcome	} from '../../../../.logos'
include { DelMoroVepAnnot	} from '../../../../.logos'  
	
include { VepAnnotation		} from '../../../../modules/07.1_VepAnnotate.nf'  
include { ExtractImpactVariant	} from '../../../../modules/07.2_SoTerms.nf'  
/*
    // Map of SO terms to impact level
    def impact_map = [
      	'transcript_ablation'	 	: 'HIGH',
	'splice_acceptor_variant'	: 'HIGH',
	'splice_donor_variant'	 	: 'HIGH',
	'stop_gained'			: 'HIGH',
	'frameshift_variant'		: 'HIGH',
	'stop_lost'			: 'HIGH',
	'start_lost'			: 'HIGH',
	'transcript_amplification'	: 'HIGH',
	'feature_elongation'		: 'HIGH',
	'feature_truncation' 		: 'HIGH',
	'inframe_insertion'		: 'MODERATE',
	'inframe_deletion'		: 'MODERATE',
	'missense_variant'		: 'MODERATE',
	'protein_altering_variant'	: 'MODERATE',
	'splice_donor_5th_base_variant'	: 'LOW',
	'splice_region_variant'		: 'LOW',
	'splice_donor_region_variant'	: 'LOW',
	'splice_polypyrimidine_tract_variant'	: 'LOW',
	'incomplete_terminal_codon_variant'	: 'LOW',
	'start_retained_variant'	: 'LOW',
	'stop_retained_variant' 	: 'LOW',
	'synonymous_variant'		: 'LOW',
	'coding_sequence_variant'	: 'MODIFIER',
	'mature_miRNA_variant'		: 'MODIFIER',
	'5_prime_UTR_variant'		: 'MODIFIER',
	'3_prime_UTR_variant' 		: 'MODIFIER',
	'non_coding_transcript_exon_variant' 	: 'MODIFIER',
	'intron_variant'		: 'MODIFIER',
	'NMD_transcript_variant'	: 'MODIFIER',
	'non_coding_transcript_variant' : 'MODIFIER',
	'coding_transcript_variant'	: 'MODIFIER',
	'upstream_gene_variant'		: 'MODIFIER',
	'downstream_gene_variant'	: 'MODIFIER',
	'TFBS_ablation'			: 'MODIFIER',
	'TFBS_amplification'		: 'MODIFIER',
	'TF_binding_site_variant'	: 'MODIFIER',
	'regulatory_region_ablation'	: 'MODIFIER',
	'regulatory_region_amplification' : 'MODIFIER',
	'regulatory_region_variant'	: 'MODIFIER',
	'intergenic_variant'		: 'MODIFIER',
	'sequence_variant'		: 'MODIFIER'
    ]
*/
 

workflow VEP_ANNOTATE {

    take:
    vcf
    fasta
    genomeindex
    vepcache
    species
    assembly
    cachetype
    CacheVersion
 

    main:
    if ( params.species &&
    	 params.reference &&
    	 params.assembly &&
    	 params.toannotate &&
     	(!params.cachetype || params.cachetype == 'refseq' || params.cachetype == 'merged' ) ) {

    DelMoroVepAnnot()
    VepAnnotation(vcf, fasta, genomeindex, vepcache, species, assembly, cachetype, CacheVersion)

  // Convert map to list of tuples (term, impact)
    term_impact = Channel.from([
      	'transcript_ablation'	 	: 'HIGH',
	'splice_acceptor_variant'	: 'HIGH',
	'splice_donor_variant'	 	: 'HIGH',
	'stop_gained'			: 'HIGH',
	'frameshift_variant'		: 'HIGH',
	'stop_lost'			: 'HIGH',
	'start_lost'			: 'HIGH',
	'transcript_amplification'	: 'HIGH',
	'feature_elongation'		: 'HIGH',
	'feature_truncation' 		: 'HIGH',
	'inframe_insertion'		: 'MODERATE',
	'inframe_deletion'		: 'MODERATE',
	'missense_variant'		: 'MODERATE',
	'protein_altering_variant'	: 'MODERATE',
	'splice_donor_5th_base_variant'	: 'LOW',
	'splice_region_variant'		: 'LOW',
	'splice_donor_region_variant'	: 'LOW',
	'splice_polypyrimidine_tract_variant'	: 'LOW',
	'incomplete_terminal_codon_variant'	: 'LOW',
	'start_retained_variant'	: 'LOW',
	'stop_retained_variant' 	: 'LOW',
	'synonymous_variant'		: 'LOW',
	'coding_sequence_variant'	: 'MODIFIER',
	'mature_miRNA_variant'		: 'MODIFIER',
	'5_prime_UTR_variant'		: 'MODIFIER',
	'3_prime_UTR_variant' 		: 'MODIFIER',
	'non_coding_transcript_exon_variant' 	: 'MODIFIER',
	'intron_variant'		: 'MODIFIER',
	'NMD_transcript_variant'	: 'MODIFIER',
	'non_coding_transcript_variant' : 'MODIFIER',
	'coding_transcript_variant'	: 'MODIFIER',
	'upstream_gene_variant'		: 'MODIFIER',
	'downstream_gene_variant'	: 'MODIFIER',
	'TFBS_ablation'			: 'MODIFIER',
	'TFBS_amplification'		: 'MODIFIER',
	'TF_binding_site_variant'	: 'MODIFIER',
	'regulatory_region_ablation'	: 'MODIFIER',
	'regulatory_region_amplification' : 'MODIFIER',
	'regulatory_region_variant'	: 'MODIFIER',
	'intergenic_variant'		: 'MODIFIER',
	'sequence_variant'		: 'MODIFIER'
    ].collect { k, v -> tuple(k, v) })

    term_impact
        .combine(VepAnnotation.out.vcf)
        .map { term, impact, file ->
            // Extract filename (last part of path) and take portion before first '_'
            def fileName = file.toString().split('/')[-1].split('_')[0]
            tuple(fileName, term, impact, file) 
        }
        .set { soImpctVcf }

    ExtractImpactVariant(soImpctVcf)
 
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



 
