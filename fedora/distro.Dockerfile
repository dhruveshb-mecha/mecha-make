# Use Debian Bookworm as the base image
FROM fedora:42

# Set non-interactive frontend for dnf
ENV DNF_FLAGS="--setopt=install_weak_dependencies=False"

# Install basic dependencies including cmake install sudo curl git rsync cpio @development-tools bc make gcc elfutils-libelf-devel openssl-devel flex bison dwarves ncurses-devel cpio rsync openssl-devel-engine rpm-build rpmdevtools dwarves openssl perl
RUN dnf -y upgrade && \
    dnf -y install --skip-broken sudo curl git rsync cpio @development-tools bc make gcc elfutils-libelf-devel openssl-devel flex bison uboot-tools mkpasswd dwarves ncurses-devel openssl-devel-engine rpm-build rpmdevtools openssl perl nu dnf5  && \
    dnf clean all

# Set up working directory
WORKDIR /build

# setup assets directory
RUN mkdir -p /build/assets

# Copy the compositor directory
COPY fedora/distro /build/fedora/distro

# Copy uboot directory
COPY uboot /build/uboot

# Log the files in the /build directory
RUN echo "Logging the files in the /build directory" && ls -la /build

# Build and install Wayland and other packages using Nushell script
RUN echo "Building packages" && \
    cd /build/fedora/distro && \
    ls -la && \
    nu build-fedora.nu mecha-comet-m-gen1 /build/assets

# Set the default command to bash
CMD ["/bin/bash"]