# Welcome to DelMoro Documentation

<div style="text-align: justify;">

<p><strong>DelMoro</strong> is a comprehensive and user-friendly <strong>Nextflow</strong>-based workflow designed for end-to-end processing of next-generation sequencing (NGS) data — from raw read quality control to annotated variant calls.</p>

<p><strong>DelMoro</strong> simplifies complex bioinformatics analyses into a streamlined and reproducible workflow that adapts easily to different environments and computing infrastructures.</p> 

  <p>While <strong>DelMoro</strong> can be used for research purposes, its primary objective is to provide users with a reliable bioinformatics pipeline for diagnostic applications, implementing best practices for upstream analysis of Illumina-based short-read sequencing data. </p>
  </div>
 
---

##  DelMoro Capabilities
DelMoro automates the entire genomic variant calling pipeline, including:

1. **Raw Data Quality Control**: Ensures input FASTQ files are high quality using tools like:  
2. **Read Trimming**: Trims adapters and low-quality bases with your choice of:
3. **Alignment**:Aligns reads to a reference genome using:  
4. **Base Recalibration**: Applies GATK's best practices for base Recalibration.
5. **Variant Calling**: Indentify SNPs and short indels.
6. **Variant Filtering**: Filter Variants following GATK Best practices.
7. **Variant Annotation**: Annotates variants.
8. **Coverage Depth Calculation & Reports**: generate quality assessment and traceability metrics.


---

## Powered by Nextflow

Built on the robust and flexible **Nextflow** workflow management system, DelMoro offers:

- **Portability** – Run the same workflow on your laptop, HPC cluster, or the cloud.
- **Reproducibility** – Automatic tracking of code versions, parameters, and inputs.
- **Scalability** – Seamless parallelization and job scheduling across different computing resources.
- **Modularity** – Easily extend or modify steps for custom analyses.
- **Resumability** – Resume interrupted runs without starting over.

---

## Flexible Environment Support

You can run DelMoro with your preferred software environment, including:

- **Conda** – Lightweight and easy-to-use environment management.
- **Mamba** – A faster Conda alternative for efficient package resolution.
- **Docker** – Containerized execution for guaranteed reproducibility.
- **Singularity / Apptainer** – HPC-friendly containers with user-level execution.
- **Nextflow Wave** – Monitor runs and launch in the cloud with ease.

---

## Get Started

Jump to the [Quickstart](1quickstart.md) guide to start processing your own data with just a few configuration changes.
