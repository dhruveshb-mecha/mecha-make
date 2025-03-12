# Use Debian Bookworm as the base image
FROM mechaorg/debian-base:latest

# Set up working directory
WORKDIR /build

# setup assets directory
RUN mkdir -p /build/assets


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