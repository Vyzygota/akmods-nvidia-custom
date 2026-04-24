ARG FEDORA_VERSION=latest
FROM fedora:${FEDORA_VERSION} AS builder
# Przyjmujemy dynamiczną wersję Nvidii ze skryptu GitHub Actions
ARG NVIDIA_VERSION
WORKDIR /build
RUN dnf install -y dnf5 && \
    # Kernel zawsze z repozytorium 'updates' (automatycznie najświeższy dla danej Fedory)
    dnf5 install -y wget rpm-build make gcc gcc-c++ dkms findutils systemd-devel kernel kernel-devel
# POBIERANIE WERSJI ZMIENNEJ ${NVIDIA_VERSION} WYKRYTEJ W NOCY
RUN mkdir -p /rpms/nvidia && \
    wget https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run -O /build/nvidia.run && \
    chmod +x /build/nvidia.run
# ... tutaj rutyna kompilacji DKMS ...
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kuję Pancerz Ochronny modułów NVIDII v${NVIDIA_VERSION} do super-kernela v${KERNEL_VERSION}..." && \
    mkdir -p /rpms/kmods && \
    find /var/lib/dkms/ -name "*.ko" -exec cp {} /rpms/kmods/ \;
FROM scratch
COPY --from=builder /rpms/ /rpms/
