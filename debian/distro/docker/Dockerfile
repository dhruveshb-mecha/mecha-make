# Use the Ubuntu 22.04 base image
FROM ubuntu:22.04

# Copy all files from the debian directory except those in .dockerignore
COPY ../debian /debian/
COPY ../kernel /kernel/

# Set the working directory inside the container
WORKDIR /debian

# Install dependencies and update the package list
RUN apt-get update && \
    apt-get install -y \
    curl \
    sudo \
    git \
    rsync \
    debootstrap \
    qemu-user-static \
    cpio \
    unzip 

# install ssh key
RUN mkdir -p /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
# COPY id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa
# RUN chmod 600 /root/.ssh/id_rsa.pub
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Install Nushell
RUN curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg
RUN echo "deb https://apt.fury.io/nushell/ /" | tee /etc/apt/sources.list.d/fury.list
RUN apt update
RUN apt install nushell

#make build directory
RUN mkdir ../build

#this is the command to run when the container starts nu build.nu mecha-comet-m-gen1 ../build 

CMD ["nu", "build-debian.nu", "mecha-comet-m-gen1", "../build"]




