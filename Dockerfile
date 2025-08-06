# Use NVIDIA CUDA base image with Python 3.8
FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV CONDA_OVERRIDE_CUDA=11.8
ENV INTEL_JIT_PROVIDER=0

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
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget --no-check-certificate https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh

# Add conda to PATH
ENV PATH="/opt/conda/bin:$PATH"

# Update certificates and configure conda
RUN update-ca-certificates \
    && conda config --set ssl_verify false \
    && conda config --set channel_priority strict

# Create conda environment using conda-forge only
RUN conda create -n ASP python=3.8 -c conda-forge --override-channels -y

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "ASP", "/bin/bash", "-c"]

# Install PyTorch with CUDA support using pip (avoids Intel JIT issues)
RUN pip install --trusted-host download.pytorch.org --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org torch==1.13.1+cu118 torchvision==0.14.1+cu118 torchaudio==0.13.1+cu118 --index-url https://download.pytorch.org/whl/cu118

# Install other dependencies
RUN conda install -c conda-forge \
    scipy \
    dominate \
    opencv \
    pillow \
    "numpy<2" \
    visdom \
    packaging \
    gputil \
    --override-channels -y

# Install additional dependencies with pip
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --no-cache-dir \
    tensorboard \
    matplotlib \
    seaborn \
    tqdm

# Activate the environment
RUN echo "conda activate ASP" >> ~/.bashrc

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Create directories for data and results
RUN mkdir -p /workspace/datasets \
    && mkdir -p /workspace/checkpoints \
    && mkdir -p /workspace/results

# Set default command
CMD ["conda", "run", "-n", "ASP", "python", "-m", "experiments", "mist", "train", "0"]