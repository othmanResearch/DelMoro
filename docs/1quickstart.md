# Installing and Managing Dependencies

<div style="text-align: justify;">

<p>This guide helps you set up the required tools, configure your environment, and run the pipeline on your sequencing data. The software dependencies required to execute the various stages of the DelMoro workflow are specified in the `DelMoro.yml` file.</p>

</div>

## Prerequisites

Before running DelMoro, make sure the following tools are installed:

- **Nextflow** – [nextflow.io](https://www.nextflow.io/)
- **Conda** or **Mamba** – [Conda](https://docs.conda.io/en/latest/miniconda.html) or [Mamba](https://mamba.readthedocs.io/en/latest/)
- **Docker** – [docs.docker.com](https://docs.docker.com/get-docker/)
- **Singularity / Apptainer** – [apptainer.org](https://apptainer.org/)

## Clone the Pipeline

Clone the DelMoro repository from GitHub:

```bash
git clone https://github.com/othmanResearch/DelMoro.git
cd DelMoro
```

## Install All Dependencies via Conda

```bash
conda env create -f DelMoro.yml
conda activate DelMoro
```
