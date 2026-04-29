ARG FEDORA_VERSION=latest
FROM fedora:${FEDORA_VERSION} AS builder

# Przyjmujemy dynamiczne wersje przekazane z GitHub Actions
ARG NVIDIA_VERSION
ARG LINUX_VERSION
WORKDIR /build

# 1. Instalacja DNF5 i bazy narzędziowej
RUN dnf install -y dnf5 && \
    dnf5 copr enable -y @kernel-vanilla/stable && \
    mkdir -p /rpms/kernel && \
    # Pobieranie konkretnych wersji jądra wybiórczo pająkiem
    dnf5 download --destdir=/rpms/kernel \
        kernel-${LINUX_VERSION}* \
        kernel-core-${LINUX_VERSION}* \
        kernel-modules-${LINUX_VERSION}* \
        kernel-modules-core-${LINUX_VERSION}* \
        kernel-modules-extra-${LINUX_VERSION}* && \
    # Instalacja pobranych pakietów oraz narzędzi kompilacji
    dnf5 install -y /rpms/kernel/*.rpm wget rpm-build make gcc gcc-c++ dkms findutils systemd-devel kernel-devel-${LINUX_VERSION}*

# 2. Pobieranie sterownika NVIDIA (.run)
RUN mkdir -p /rpms/nvidia && \
    wget https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run -O /build/nvidia.run && \
    chmod +x /build/nvidia.run

# 3. Kompilacja modułów jądra NVIDIA z "Wytrychem" na Kernel 7.0+ i GCC 16
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kuję Pancerz Ochronny modułów NVIDII v${NVIDIA_VERSION} dla jądra ${KERNEL_VERSION}..." && \
    ./nvidia.run --extract-only && \
    cd NVIDIA-Linux-x86_64-${NVIDIA_VERSION}/kernel && \
    # OBJTOOL=true ignoruje błędy 'naked return' (MITIGATION_RETHUNK)
    # NV_EXTRA_CFLAGS wycisza nowe restrykcje GCC 16, aby ostrzeżenia nie przerywały buildu
    make -j$(nproc) \
        IGNORE_CC_MISMATCH=1 \
        OBJTOOL=true \
        SYSSRC=/usr/src/kernels/${KERNEL_VERSION} \
        SYSOUT=/usr/src/kernels/${KERNEL_VERSION} \
        NV_EXTRA_CFLAGS="-Wno-error -Wno-expansion-to-defined -Wno-implicit-function-declaration" \
        modules && \
    mkdir -p /rpms/kmods && \
    cp *.ko /rpms/kmods/

# 4. Kompilacja sterownika LenovoLegionLinux
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kompilacja LenovoLegionLinux dla jądra ${KERNEL_VERSION}..." && \
    wget https://github.com/johnfanv2/LenovoLegionLinux/archive/refs/heads/main.tar.gz -O lenovo.tar.gz && \
    tar -xf lenovo.tar.gz && \
    cd LenovoLegionLinux-main/kernel_module && \
    make -j$(nproc) -C /usr/src/kernels/${KERNEL_VERSION} M=$(pwd) modules && \
    cp *.ko /rpms/kmods/

# 5. Tworzenie Dummy RPM dla oszukania zależności Bazzite/uBlue
RUN echo "Name: kernel-nvidia" > /build/dummy.spec && \
    echo "Version: 99.99.99" >> /build/dummy.spec && \
    echo "Release: 1%{?dist}" >> /build/dummy.spec && \
    echo "Epoch: 3" >> /build/dummy.spec && \
    echo "Summary: Dummy package for kernel-nvidia to satisfy atomic dependencies" >> /build/dummy.spec && \
    echo "License: MIT" >> /build/dummy.spec && \
    echo "Provides: nvidia-kmod = 3:${NVIDIA_VERSION}" >> /build/dummy.spec && \
    echo "" >> /build/dummy.spec && \
    echo "%description" >> /build/dummy.spec && \
    echo "Dummy package to bypass version checks on Bazzite/uBlue." >> /build/dummy.spec && \
    echo "%files" >> /build/dummy.spec && \
    rpmbuild -ba /build/dummy.spec && \
    mkdir -p /rpms/dummy && \
    cp /root/rpmbuild/RPMS/*/*.rpm /rpms/dummy/

# 6. Eksport gotowych paczek do czystego obrazu
FROM scratch
COPY --from=builder /rpms/ /rpms/
