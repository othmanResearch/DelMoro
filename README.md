![mainWlcPipeline](./.DelMoroWlc.png)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.10.5-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

---
## Introduction 

<div style="text-align: justify;">
DelMoro is a Nextflow pipeline for genome/exome variant detection across species, offering two modes: (1) stepmode for modular execution of 8 subworkflows and (2) fullmode for automated end-to-end analysis. Built for reproducibility with Conda/Mamba/Docker/Singuilarity and wave support, it enables both granular optimization and high-throughput processing. The dual architecture supports diverse applications from exploratory research with iterative refinement to clinical grade batch analysis,while maintaining GATK best practices.This balance between stepmode and fullmode offers adaptability and standardization which makes DelMoro suitable for both developmental genomics and production-scale variant calling.
</div>
---

## Pipelines Tools 
1. Raw Data Quality Control : Ensures input FASTQ files are high quality using tools like:
- [FastQC]()
- [MultiQC]()

2. Read Trimming : Trims adapters and low-quality bases with your choice of:
- [Trimmomatic]()
- [Fastp]()
- [BBDuk]()

3. Alignment Aligns reads to a reference genome using:
- [BWA]()
- [BWA-MEM2]()

Metrics:
- [CollectAlignmentSummaryMetrics]()
- [CollectInsertSizeMetrics]()
- [CollectGcBiasMetrics]()
- [QualiMap]()

BigWigs:
- [bamCoverage]()

BigWigs Plotting:
- [pyBigWig]()

4. Base Recalibration Applies GATK's best practices with:
- [GATK]()
- Metrics, BigWigs, and plotting

5. Variant Calling Detects SNPs and indels using:
- [GATK]() HaplotypeCaller

6. Variant Annotation Annotates variants using:
- [Variant Effect Predictor]() 

7. Reportin with :
- [Reportlab]()

### Workflow

![Pipeline](./pipelineDelMoro.png)

---
##  Usage

> [!NOTE]
> Please make sure to check help menu with `--help` before running the workflow on actual data.

~~~bash
 nextflow run main.nf --help
~~~


~~~
Usage   : nextflow run main.nf <modality> [--exec <module>] <params>

Modality: - --fullmode  : Executing   full   mode from fastq until vaiant calling.
          - --stepmode  : Executing   different   modules   in   standalone  mode.
~~~

#### Executing fullmode :  
~~~
nextflow run main.nf  
    --fullmode
    --input  
    --reference   | [--igenome ]   
    [--aligner bwamem2]  
    [--mode cohort]  
    [--bqsr]  
    [--knownsite1 ,--knownsite2 |--ivcf1 ,--ivcf2 ]
~~~

### Executing stepmode :  

~~~
nextflow run main.nf  
    --stepmode
    --exec <module>   

Module  : - rawqc       : Check           quality      of     raw           reads. 
          - trim        : Remove low-quality bp and adapters & checks its quality.
          - refidx      : Index   the    reference   genome    for      alignment.
          - align       : Align     reads      to     the     reference    genome.
          - bqsr        : Base          Quality         Score       recalibration.
          - callsnp     : Detect           SNPs      from      aligned      reads.
          - annotate    : annotate                  vfc                      file.
          - reporting   : Auto          Generate   PDF    of      vcf     reports.                                                                                                                                         
          - help                                                                                                                                                                                                           
          - version 
~~~


