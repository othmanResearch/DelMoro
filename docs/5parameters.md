# Pipeline Parameters

<div style="text-align: justify;"> 

This section provides a comprehensive overview of all configurable parameters available in the pipeline. Each parameter can be set via the command line or a configuration file to customize the behavior of the workflow. Default values are indicated alongside a ⊕ icon, and brief descriptions are provided to help guide proper usage based on your data and analysis goals.

</div>

---

## General Settings
- `--cpus`  = Number of CPUs allocated to the pipeline. <span title="Default: 4">⊕</span>  
- `--outdir` = Directory where all outputs will be saved. <span title="Default: ./outdir">⊕</span>


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
- `--metrics` = Run Metrics Processes for Bam files   . <span title="[Optional] - Default: false">⊕</span>  
- `--depth`	= Minimum depth in coverage bin plots <span title="[Optional] - Default: 0 ">⊕</span>  
- `--saveImg` = Save images( plots ) from bigwig files <span title="[Optional] - Default: false">⊕</span>  

## Base Quality Score Recalibration 
- `--bam` = CSV with BAM file paths. <span title="Default: ./CSVs/4_samplesheetForBamFiles.csv">⊕</span>  
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--knownsite1` = First known variants VCF file (for BQSR). <span title="Default: ./knownsites/1000g_gold_standard.indels.filtered.vcf">⊕</span>  
- `--knownsite2` = Second known variants VCF file. <span title="Default: ./knownsites/GCF.38.filtered.renamed.vcf">⊕</span>
- `--ivcf1` = VCF resource for BQSR (downloaded). <span title="[Optional] - Default: null">⊕</span>  
- `--ivcf2` = Second VCF resource for BQSR. <span title="[Optional] - Default: null">⊕</span>
- `--metrics` = Run Metrics Processes for Bam files   . <span title="[Optional] - Default: false">⊕</span>
- `--depth`	= Minimum depth in coverage bin plots <span title="[Optional] - Default: 0 ">⊕</span>  
- `--saveImg` = Save images( plots ) from bigwig files <span title="[Optional] - Default: false">⊕</span>  

## Variant Calling
- `--reference` = Path to reference genome FASTA file. <span title="Default: ./Reference_Genome/*.fa">⊕</span>  
- `--tovarcall` = CSV with recalibrated BAM files. <span title="Default: ./CSVs/5_samplesheetReclibFiles.csv">⊕</span>  
- `--mode` = Output type: onlyVCF  or cohortGVCF <span title="Default: onlyVCF = vcf file / cohorteGCVF = Gvcf file">⊕</span>  
 
## Annotation (VEP)
- `--species` = Species name for VEP cache. <span title="Default: null">⊕</span>  
- `--cachetype` = VEP cache type (`refseq` or `merged`). <span title="Default: null">⊕</span>  
- `--assembly` = Genome assembly version. <span title="Default: null">⊕</span>  
- `--cachedir` = Path to VEP cache directory. <span title="Default: .vepcachedir">⊕</span>

## Reporting 
- `--metaPatients` = Csv of patiens' Metadata + vcf paths <span title="Default: null">⊕</span>
- `--metaYaml` = Yaml file of Physician metadata + executions steps info <span title="Default: null">⊕</span>


