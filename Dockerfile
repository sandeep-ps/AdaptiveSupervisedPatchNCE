# Use NVIDIA CUDA base image with Python 3.8
FROM nvidia/cuda:11.6-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    vim \
    build-essential \
    cmake \
    pkg-config \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh

# Add conda to PATH
ENV PATH="/opt/conda/bin:$PATH"

# Copy environment file
COPY environment.yml /tmp/environment.yml

# Create conda environment
RUN conda env create -f /tmp/environment.yml

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "ASP", "/bin/bash", "-c"]

# Activate the environment
RUN echo "conda activate ASP" >> ~/.bashrc

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Install additional dependencies that might be needed
RUN pip install --no-cache-dir \
    tensorboard \
    matplotlib \
    seaborn \
    tqdm

# Create directories for data and results
RUN mkdir -p /workspace/datasets \
    && mkdir -p /workspace/checkpoints \
    && mkdir -p /workspace/results

# Set default command
CMD ["conda", "run", "-n", "ASP", "python", "-m", "experiments.mist", "train", "0"]