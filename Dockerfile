FROM ubuntu:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    neovim \
    curl \
    tar \
    build-essential \
    strace \
    && rm -rf /var/lib/apt/lists/*

# Download and install Zig manually
ENV ZIG_VERSION=0.14.0
RUN curl -L https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz | tar -xJ && \
    mv zig-linux-x86_64-${ZIG_VERSION} /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig


RUN apt-get update && apt-get install -y \
    debootstrap \
    && rm -rf /var/lib/apt/lists/*

# Create rootfs using debootstrap
RUN debootstrap --variant=minbase bookworm /rootfs http://deb.debian.org/debian

# Create app directory
WORKDIR /zigsandbox

# Copy code into container
COPY . .

