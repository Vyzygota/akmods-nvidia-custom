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

# Uruchamiamy instalator NVIDIA i kompilujemy same moduły jądra
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kuję Pancerz Ochronny modułów NVIDII v${NVIDIA_VERSION} do super-kernela v${KERNEL_VERSION}..." && \
    cd /build && \
    ./nvidia.run --extract-only && \
    cd NVIDIA-Linux-x86_64-${NVIDIA_VERSION}/kernel && \
    make IGNORE_CC_MISMATCH=1 SYSSRC=/usr/src/kernels/${KERNEL_VERSION} SYSOUT=/usr/src/kernels/${KERNEL_VERSION} modules && \
    mkdir -p /rpms/kmods && \
    cp *.ko /rpms/kmods/

# Kujemy sterownik LenovoLegionLinux z kodu źródłowego
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kompilacja LenovoLegionLinux dla kernela ${KERNEL_VERSION}..." && \
    cd /build && \
    wget https://github.com/johnfanv2/LenovoLegionLinux/archive/refs/heads/main.tar.gz -O lenovo.tar.gz && \
    tar -xf lenovo.tar.gz && \
    cd LenovoLegionLinux-main/kernel_module && \
    make KDIR=/usr/src/kernels/${KERNEL_VERSION} && \
    cp *.ko /rpms/kmods/

# Tworzymy fałszywy (dummy) RPM, który zablokuje Bazzite od narzekania na brak pakietów Nvidii
RUN echo "Name: kernel-nvidia" > /build/dummy.spec && \
    echo "Version: 99.99.99" >> /build/dummy.spec && \
    echo "Release: 1%{?dist}" >> /build/dummy.spec && \
    echo "Epoch: 3" >> /build/dummy.spec && \
    echo "Summary: Dummy package for kernel-nvidia" >> /build/dummy.spec && \
    echo "License: MIT" >> /build/dummy.spec && \
    echo "Provides: nvidia-kmod = 3:${NVIDIA_VERSION}" >> /build/dummy.spec && \
    echo "" >> /build/dummy.spec && \
    echo "%description" >> /build/dummy.spec && \
    echo "Dummy" >> /build/dummy.spec && \
    echo "%files" >> /build/dummy.spec && \
    rpmbuild -ba /build/dummy.spec && \
    mkdir -p /rpms/dummy && \
    cp /root/rpmbuild/RPMS/*/*.rpm /rpms/dummy/

FROM scratch
COPY --from=builder /rpms/ /rpms/
