# Requirements

This page outlines the software, system, and data requirements needed to successfully run **DelMoro**.

---

## Software Requirements

The following tools must be **available on your system**. Installation instructions are provided in the [Quickstart](1quickstart.md).

- **Nextflow** (≥ 21.04.0)
- Either:
  - **Conda** or **Mamba** (for managing software environments)
  - **Docker** or **Singularity/Apptainer** (for containerized execution)
- **Java 8 or 11** (required by Nextflow)

> ⚠️ Ensure all tools are available in your `PATH`. Test by running `nextflow -v` and `java -version`.

---

## Required Inputs

DelMoro expects the following **minimum input data**:

| Type              | Description                                          |
|-------------------|------------------------------------------------------|
| FASTQ files       | Paired-end                                           |
| Reference genome  | Manually Downloaded Or Retreived with igenome option |
| Annotation (optional) | Require Reference Fasta file and  vep cache          |

> Input and output details are available in the [Inputs & Outputs](4io.md) section.

---

## Hardware Recommendations

DelMoro is designed to scale across different systems. Here are typical hardware guidelines:

| Resource       | Minimum | Recommended               |
|----------------|---------|---------------------------|
| CPU Cores      | 4       | ≥ 8                       |
| RAM            | 8 GB    | ≥ 32 GB                   |
| Disk Space     | 20 GB   | ≥ 100 GB (for large runs) |
| Executor       | Local   | cluster                   |

> For large-scale datasets, running on an HPC or cloud environment is highly recommended.

---

## Network Access

Internet access may be required to:

- Pull Docker/Singularity images
- Download Conda packages
- Retrieve reference data (if not local)
- Retrieve vep cache (if not local)


 
---

## Pre-run Checklist

Make sure the following are in place before running the pipeline:

- All required software is installed and available
- Input files are prepared and correctly named
- Sufficient compute resources are available
- Network storage or output directory is writable

Need help? See [Parameters](5parameters.md) for common setup issues.
 