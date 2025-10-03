# Use the Fedora 42 base image
FROM fedora:42

# Copy all files from the fedora directory except those in .dockerignore
COPY ../fedora /fedora/

COPY ../kernel /kernel/

# Set the working directory inside the container
WORKDIR /fedora 

# Install dependencies and update the package list
RUN dnf update && \
    dnf install -y \
    curl \
    sudo \
    git \
    rsync \
    debootstrap \
    qemu-user-static \
    cpio \
    nu

# install ssh key
RUN mkdir -p /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
# COPY id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa
# RUN chmod 600 /root/.ssh/id_rsa.pub
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

#make build directory
RUN mkdir ../build

#this is the command to run when the container starts nu build.nu mecha-comet-m-gen1 ../build 

CMD ["nu", "build-fedora.nu", "mecha-comet-m-gen1", "../build"]




