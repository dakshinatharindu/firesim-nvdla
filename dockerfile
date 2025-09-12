# Use Ubuntu 22.04 as base image
FROM ubuntu:20.04

# Set environment variables to prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update package list and install basic packages
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    perl \
    python3 \
    python3-pip \
    python3-dev \
    curl \
    wget \
    vim \
    nano \
    ca-certificates \
    sudo \
    help2man perl python3 make autoconf g++ flex bison ccache \
    libgoogle-perftools-dev numactl perl-doc \
    libfl2 \
    libfl-dev \
    zlib1g zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Verilator
RUN cd /tmp && \
    git clone https://github.com/verilator/verilator && \
    cd verilator && \
    git checkout v3.912 && \
    autoconf && ./configure && \
    make && \
    make install && \
    cd .. && rm -rf verilator

# Create a symlink for python (optional, for compatibility)
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install risc-v toolchain
RUN wget https://github.com/dakshinatharindu/firesim-nvdla/releases/download/riscv64/riscv_64.tar.gz
RUN tar -xvf riscv64.tar.gz -C /opt
RUN mv /opt/opt/riscv /opt/riscv
ENV PATH="/opt/riscv/bin:${PATH}"
RUN rm -rf riscv64.tar.gz

# Create nvdla user with sudo privileges
RUN useradd -m -s /bin/bash nvdla && \
    echo "nvdla ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to nvdla user
USER nvdla

# Set working directory
WORKDIR /home/nvdla

# Default command
CMD ["/bin/bash"]
