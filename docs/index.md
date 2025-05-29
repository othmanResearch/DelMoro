# Welcome to DelMoro Documentation

<div style="text-align: justify;">

<p><strong>DelMoro</strong> is a comprehensive and user-friendly <strong>Nextflow</strong>-based workflow designed for end-to-end processing of next-generation sequencing (NGS) data — from raw read quality control to annotated variant calls.</p>

<p>Whether you're a researcher, bioinformatician, or lab technician, <strong>DelMoro</strong> simplifies complex bioinformatics analyses into a streamlined and reproducible workflow that adapts easily to different environments and computing infrastructures.</p>

</div>
 
---

##  What DelMoro Does

DelMoro automates the entire genomic variant calling pipeline, including:

1. **Raw Data Quality Control**  
   Ensures input FASTQ files are high quality using tools like:
   - `FastQC`
   - `MultiQC`

2. **Read Trimming**  
   Trims adapters and low-quality bases with your choice of:
   - `Trimmomatic`
   - `Fastp`
   - `BBDuk`

3. **Alignment**  
   Aligns reads to a reference genome using:
   - `BWA`
   - `BWA-MEM2`

4. **Base Recalibration**  
   Applies GATK's best practices with:
   - `BaseRecalibrator`
   - `ApplyBQSR`

5. **Variant Calling**  
   Detects SNPs and indels using:
   - `GATK HaplotypeCaller`

6. **Variant Annotation**  
   Annotates variants using:
   - `Ensembl VEP (Variant Effect Predictor)`

7. **Coverage Depth Calculation & Reports**  
   Automatically generates coverage depth metrics for your aligned data and creates detailed reports from the VCF files to help assess the quality of your variant calls.

Each stage includes logging and quality reports to help ensure data integrity and reproducibility throughout the workflow.

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

Jump to the [Quickstart](quickstart.md) guide to start processing your own data with just a few configuration changes.
