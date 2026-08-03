FROM continuumio/miniconda3:latest

# Install required system packages
RUN apt-get update \
    && apt-get install -y procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy environment file
COPY DelMoro.yml /

# Copy pipeline
COPY . /DelMoro

# Create Conda environment
RUN conda env create -f /DelMoro.yml \
    && conda clean -afy

# Add the environment to PATH
ENV PATH=/opt/conda/envs/DelMoro/bin:$PATH

# Keep the pipeline in the image
WORKDIR /DelMoro

# Use a writable .nextflow directory in the current working directory
ENV NXF_HOME=.nextflow

# Default command
CMD ["nextflow"]
