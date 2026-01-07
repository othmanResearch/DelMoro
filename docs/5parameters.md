# Pipeline Parameters

<div style="text-align: justify;"> 

This section provides a comprehensive overview of all configurable parameters available in the pipeline. Each parameter can be set via the command line or a configuration file to customize the behavior of the workflow. Default values are indicated alongside a ⊕ icon, and brief descriptions are provided to help guide proper usage based on your data and analysis goals.

</div>

---

## General Settings
- `--mcpus` = Maximum number of CPUs available to the entire pipeline. <span title="Default: 1">⊕</span>
- `--pcpus` = Number of CPUs allocated per process. <span title="Default: 1">⊕</span>
- `--outdir` = Directory where all outputs will be saved. <span title="Default: ./outdir">⊕</span>

???+ note "💡 Explanation"
    - If the user only specifies `--pcpus`, then `mcpus` is set equal to `pcpus`.  
      This means the pipeline will execute tasks **sequentially**, using the top available CPUs per process.  

    - If `--mcpus` is greater than `2 x pcpus`, the `maxForks` will be set to 2, allowing **up to 2 tasks to run in parallel**.


## Initialize my pipeline 

- `--generate` = CSV <span title="Prepare pre-required csv files for the pipeline">⊕</span>
- `--basedon` = CSV to generate other input CSVs from. <span title="Default: ./CSVs/1_samplesheetForRawQC.csv">⊕</span>  

## Input Csv Files
- `--rawreads` = CSV file with raw read file paths. <span title="Default: ./CSVs/1_samplesheetForRawQC.csv">⊕</span>  
- `--tobetrimmed` = CSV with read paths + trimming parameters. <span title="Default: ./CSVs/2_SamplesheetForTrimming.csv">⊕</span>  
- `--tobealigned` = CSV with trimmed read paths. <span title="Default: ./CSVs/3_samplesheetForAssembly.csv">⊕</span>  
- `--bam` = CSV with BAM file paths. <span title="Default: ./CSVs/4_samplesheetForBamFiles.csv">⊕</span>  
- `--tovarcall` = CSV with recalibrated BAM files. <span title="Default: ./CSVs/5_samplesheetReclibFiles.csv">⊕</span>  
- `--toannotate` = CSV with VCF file paths. <span title="Default: ./CSVs/6_samplesheetvcfFiles.csv">⊕</span>


## Raw Reads Quality Check
- `--rawreads` = CSV file with raw read file paths. <span title="Default: ./CSVs/1_samplesheetForRawQC.csv">⊕</span>  

## Trimming Options
- `--tobetrimmed` = CSV with read paths + trimming parameters. <span title="Default: ./CSVs/2_SamplesheetForTrimming.csv">⊕</span>  
- `--trimmomatic` = Enable trimming with Trimmomatic. <span title="Default: false">⊕</span>  
- `--fastp` = Enable trimming with Fastp. <span title="Default: false">⊕</span>  
- `--bbduk` = Enable trimming with BBDuk. <span title="Default: false">⊕</span>  
- `--adapters` = Path to adapter file for trimming tools. <span title="[Optional] - Default: null">⊕</span>
 
## Indexing Reference File 
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--igenome` = iGenomes key to download reference data. <span title="Default: null">⊕</span>  

## Alignment
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--tobealigned` = CSV with trimmed read paths. <span title="Default: ./CSVs/3_samplesheetForAssembly.csv">⊕</span>  
- `--aligner` = Alignment tool to use (`bwa`, `bwamem2`, etc.). <span title="Default: null (bwa)">⊕</span>
- `--region` = Extract region from BAM (`chr:start-end`). <span title="[Optional] - Default: null">⊕</span>  
- `--generate` = Generate coverage from bed file <span title="[Optional] - Default: null">⊕</span>  
- `--bedtarget` = BED file for coverage extraction. <span title="[Optional] - Default: null">⊕</span>
- `--keepinter` =  Keep intermediate BAM files derived from alignment. <span title="[Optional] - Default: false">⊕</span>
- `--report` = Enables Metrics-bigwigs-html summary for Bam files. <span title="[Optional] - Default: false">⊕</span>   
- `--depth`	= Minimum depth in coverage bin plots <span title="[Optional] - Default: 0 ">⊕</span>  
- `--saveImg` = Save images( plots ) from bigwig files <span title="[Optional] - Default: false">⊕</span>  

## Base Quality Score Recalibration 
- `--bam` = CSV with BAM file paths. <span title="Default: ./CSVs/4_samplesheetForBamFiles.csv">⊕</span>  
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--knownsite1` = First known variants VCF file (for BQSR). <span title="Default: ./knownsites/1000g_gold_standard.indels.filtered.vcf">⊕</span>  
- `--knownsite2` = Second known variants VCF file. <span title="Default: ./knownsites/GCF.38.filtered.renamed.vcf">⊕</span>
- `--ivcf1` = VCF resource for BQSR (downloaded). <span title="[Optional] - Default: null">⊕</span>  
- `--ivcf2` = Second VCF resource for BQSR. <span title="[Optional] - Default: null">⊕</span>
- `--report` = Enables Metrics-bigwigs-html summary for Bam files. <span title="[Optional] - Default: false">⊕</span>   
- `--depth`	= Minimum depth in coverage bin plots <span title="[Optional] - Default: 0 ">⊕</span>  
- `--saveImg` = Save images( plots ) from bigwig files <span title="[Optional] - Default: false">⊕</span>  

## Variant Calling
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--tovarcall` = CSV with recalibrated BAM files. <span title="Default: ./CSVs/5_samplesheetReclibFiles.csv">⊕</span>  
- `--mode` = Output type: onlyvcf to generate a vcf for each input <span title="Default: null : generates a cohort gvcf ">⊕</span>  
 
## Filtering 
- `--tofilter` = Path to the CSV file containing variants to filter. <span title="Default: null ">⊕</span>
- `--QD` = Quality by Depth: variant confidence normalized by depth. <span title="Default: 2.0">⊕</span>
- `--QUAL` = Overall variant quality score. <span title="Default: 30.0">⊕</span>
- `--SOR` = Strand Odds Ratio: measures strand bias. <span title="Default: 3.0">⊕</span>
- `--FSSNP` = Fisher Strand p-value for strand bias (SNPs). <span title="Default: 60.0">⊕</span>
- `--MQ` = RMS Mapping Quality of reads supporting the variant. <span title="Default: 40.0">⊕</span>
- `--MQRankSum` = Z-score from Wilcoxon rank sum test of Alt vs Ref read mapping qualities. <span title="Default: -12.5">⊕</span>
- `--ReadPosRankSumSNP` = Z-score from Wilcoxon rank sum test of Alt vs Ref read position within reads (SNPs). <span title="Default: -8.0">⊕</span>
- `--FSINDEL` = Fisher Strand p-value for strand bias (INDELs). <span title="Default: 200.0">⊕</span>
- `--ReadPosRankSumINDEL` = Z-score from Wilcoxon rank sum test of Alt vs Ref read position within reads (INDELs). <span title="Default: -20.0">⊕</span>

## Annotation (VEP)
- `--species` = Species name for VEP cache. <span title="Default: null">⊕</span>  
- `--cachetype` = VEP cache type (`refseq` or `merged`). <span title="Default: null">⊕</span>  
- `--assembly` = Genome assembly version. <span title="Default: null">⊕</span>  
- `--cachedir` = Path to VEP cache directory. <span title="Default: .vepcachedir">⊕</span>

## Reporting 
- `--metaPatients` = Csv of patiens' Metadata + vcf paths <span title="Default: null">⊕</span>
- `--metaYaml` = Yaml file of Physician metadata + executions steps info <span title="Default: null">⊕</span>


