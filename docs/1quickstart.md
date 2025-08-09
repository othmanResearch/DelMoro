# Quickstart Guide

<div style="text-align: justify;">

<p>Welcome to the Quickstart guide for <strong>DelMoro</strong> — a modular, scalable, and portable workflow for NGS data processing built with <a href="https://www.nextflow.io/">Nextflow</a>.</p>

<p>This guide helps you set up the required tools, configure your environment, and run the pipeline on your sequencing data.</p>

</div>

---

## 1. Prerequisites

Before running DelMoro, make sure the following tools are installed:

- **Nextflow** – [nextflow.io](https://www.nextflow.io/)
- **Conda** or **Mamba** – [Conda](https://docs.conda.io/en/latest/miniconda.html) | [Mamba](https://mamba.readthedocs.io/en/latest/)
- **Docker** – [docs.docker.com](https://docs.docker.com/get-docker/)
- **Singularity / Apptainer** – [apptainer.org](https://apptainer.org/)

These tools allow DelMoro to run reproducibly across systems using software environments, containers, or HPC clusters.

---

## 2. Clone the Pipeline

Clone the DelMoro repository from GitHub:

```bash
git clone https://github.com/othmanResearch/DelMoro.git
cd DelMoro
```

## 3. Install All Dependencies via Conda

```bash
mamba env create -f DelMoro.yml
conda activate DelMoro
```
