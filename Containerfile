ARG FEDORA_VERSION=latest
FROM fedora:${FEDORA_VERSION} AS builder

# Przyjmujemy dynamiczną wersję Nvidii ze skryptu GitHub Actions
ARG NVIDIA_VERSION
ARG LINUX_VERSION
WORKDIR /build

RUN dnf install -y dnf5 && \
    # Aktywujemy repozytorium Vanilla, skąd pociągniemy najnowszą wersje jadra (zgodną z LINUX_VERSION ze spidera)
    dnf5 copr enable -y @kernel-vanilla/stable && \
    mkdir -p /rpms/kernel && \
    dnf5 download --destdir=/rpms/kernel kernel-${LINUX_VERSION}* kernel-core-${LINUX_VERSION}* kernel-modules-${LINUX_VERSION}* kernel-modules-core-${LINUX_VERSION}* kernel-modules-extra-${LINUX_VERSION}* && \
    dnf5 install -y /rpms/kernel/*.rpm wget rpm-build make gcc gcc-c++ dkms findutils systemd-devel kernel-devel-${LINUX_VERSION}*

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
