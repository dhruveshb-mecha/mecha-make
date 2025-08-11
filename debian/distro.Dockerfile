# Use Debian trixie as the base image
FROM debian:trixie

# Set non-interactive frontend for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update base image and install basic dependencies including cmake
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    wget \
    sudo \
    apt \
    debootstrap \
    qemu-user-static \
    whois \
    u-boot-tools \
    curl \
    gnupg

# Download and install Nushell
RUN curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg
RUN echo "deb https://apt.fury.io/nushell/ /" | tee /etc/apt/sources.list.d/fury.list
RUN apt update
RUN apt install nushell

# Set up working directory 
WORKDIR /build

# setup assets directory
RUN mkdir -p /build/assets

# Create necessary directories
# RUN mkdir -p deps/wayland deps/wayland-protocols deps/dpkg-dev deps/libliftoff deps/libdisplay-info deps/wlroots deps/labwc

# Copy the compositor directory
COPY debian/distro /build/debian/distro

# Copy uboot directory
COPY uboot /build/uboot

# Log the files in the /build directory
RUN echo "Logging the files in the /build directory" && ls -la /build

# Build and install Wayland and other packages using Nushell script
RUN echo "Building packages" && \
    cd /build/debian/distro && \
    ls -la && \
    nu build-debian.nu mecha-comet-m-gen1 /build/assets

# Set the default command to bash
CMD ["/bin/bash"]