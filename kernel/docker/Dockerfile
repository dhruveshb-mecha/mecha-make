# Use the Ubuntu 22.04 base image
FROM ubuntu:22.04

# Copy all files from the bootloader directory except those in .dockerignore
COPY ../kernel /kernel/

# Set the working directory inside the container
WORKDIR /kernel

# Install dependencies and update the package list
RUN apt-get update && \
    apt-get install -y \
    curl \
    sudo \
    git \
    rsync \
    cpio

# install ssh key
RUN mkdir -p /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
# COPY id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa
# RUN chmod 600 /root/.ssh/id_rsa.pub
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts


# Install Nushell
RUN curl -L https://github.com/nushell/nushell/releases/download/0.95.0/nu-0.95.0-x86_64-unknown-linux-gnu.tar.gz | tar xz \
    && mv nu-0.95.0-x86_64-unknown-linux-gnu/nu /usr/local/bin/ \
    && rm -rf nu-0.95.0-x86_64-unknown-linux-gnu 

#make build directory
RUN mkdir ../build-kernel 

# Specify the command to run when the container starts
CMD ["nu", "build-kernel.nu", "mecha-comet-gen1", "../build"]