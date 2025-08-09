# Inputs & Outputs

<div style="text-align: justify;"> 

<p>This document outlines the required data inputs and expected outputs for each stage of the <strong>DelMoro</strong> workflow. It serves as a technical reference to guide users in preparing and interpreting files throughout the analysis process.

</div>

---

## Inputs

| Module              | Description                                                                                                                                               |
|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Quality Control** | A CSV file listing the raw FASTQ files to be assessed. Supports only paired-end reads.                                                                    |
| **Trimming**        | A CSV of reads to be trimmed. Includes optional adapter sequence file. Users may choose from various trimming tools such as Trimmomatic, fastp, or bbduk. |
| **Reference Indexing** | A reference genome in FASTA format. Optionally, a preconfigured iGenomes identifier may be used.                                                          |
| **Read Alignment**  | A reference genome and a set of trimmed FASTQ files. Alignment is performed per sample.                                                                   |
| **BQSR**            | Two known-site VCF files used for recalibration, along with a list of BAM files to be processed.                                                          |
| **Variant Calling** | Aligned BAM files and corresponding reference genome. Used to identify SNPs and other variants.                                                           |
| **VEP Cache Setup** | Species name to retrieve the appropriate VEP cache. Assembly and cache type may also be specified if needed.                                              |
| **VEP Annotation**  | A set of VCF files or a list of variant files to be annotated. Requires reference genome, species, and optional cache parameters.                         |

**Configuration and Usage:** 🔗 [Parameter Details](parameters.md) 🔗 [Configuration Files](config.md)
 🔗 [Running the Pipeline](running.md)
 

---

## Outputs

| Module              | Output Files                                                                                          | Description                                                               |
|---------------------|--------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| **Quality Control** | HTML QC reports for individual samples, and a combined MultiQC summary                                 | Visual quality summaries of raw sequencing reads                          |
| **Trimming**        | Trimmed FASTQ files, per-sample trimming reports, and an updated MultiQC report                        | Cleaned reads with adapter and quality trimming results                   |
| **Reference Indexing** | Dictionary, FASTA index, and algorithm-specific index files (`.dict`, `.fai`, `.bwt`, etc.)         | Files required for efficient sequence alignment and downstream analysis   |
| **Read Alignment**  | Sorted BAM files, index files (`.bai`), alignment QC metrics, and genome coverage data                 | Aligned reads with statistics for coverage and mapping quality            |
| **BQSR**            | Indexed known-site VCFs, recalibration table, and recalibrated BAM files                               | Improves accuracy of base quality scores used in variant calling          |
| **Variant Calling** | Raw VCF files containing variant calls, and a summary table                                            | Identified SNPs and indels per sample                                     |
| **VEP Cache Setup** | Directory containing locally stored VEP cache                                                          | Enables fast, offline variant annotation                                  |
| **VEP Annotation**  | Annotated VCF files (`.vcf.gz`), index files, and an HTML annotation report                            | Functionally annotated variants with summaries accessible via browser     |

---

## Notes

- All input files are provided via CSV files and must be properly formatted and consistently structured.
- Output files are organized into module-specific subdirectories under the `outdir` folder.
- Intermediate data and log files are retained by default to support transparency and reproducibility.

