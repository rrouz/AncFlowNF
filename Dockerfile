FROM condaforge/mambaforge:23.11.0-0

ARG DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    grep \
    sed \
    curl \
    bash \
    git \
    openjdk-17-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME and default timezone to avoid tzdata prompts
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV TZ=Etc/UTC

# Ensure plotting and numba caches use writable locations
ENV MPLCONFIGDIR=/tmp/mplconfig
ENV XDG_CACHE_HOME=/tmp/xdg
ENV NUMBA_CACHE_DIR=/tmp/numba
ENV NUMBA_DISABLE_CACHING=1

# Install Nextflow (skip self-update in container, use specific version)
RUN curl -fsSL https://get.nextflow.io | bash \
    && mv nextflow /usr/local/bin/nextflow \
    && chmod +x /usr/local/bin/nextflow \
    && rm -rf /root/.nextflow

# Copy environment file first (for better caching)
COPY environment.yml /tmp/environment.yml

# Create conda environment with mamba (faster than conda)
RUN mamba env create -f /tmp/environment.yml \
    && mamba clean -a -y \
    && rm /tmp/environment.yml

# Set PATH to include conda environment
ENV PATH="/opt/conda/envs/ancflow/bin:$PATH"

# Set working directory
WORKDIR /workspace

# Copy pipeline files
COPY main.nf /workspace/
COPY nextflow.config /workspace/
COPY workflows/ /workspace/workflows/
COPY modules/ /workspace/modules/
COPY bin/ /workspace/bin/
COPY conf/ /workspace/conf/

# Make scripts executable
RUN chmod +x /workspace/bin/*.py

# Create writable cache directories
RUN mkdir -p ${MPLCONFIGDIR} ${XDG_CACHE_HOME} ${NUMBA_CACHE_DIR}

# Add labels
LABEL description="AncflowNF - Ancestral Sequence Reconstruction Pipeline"
LABEL maintainer="AncflowNF"
LABEL version="2.0.0"

# Default command (Nextflow will override this)
CMD ["/bin/bash"]

