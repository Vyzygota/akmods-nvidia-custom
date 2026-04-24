FROM fedora:43 AS builder
WORKDIR /build
# 1. Wymagane narzędzia
RUN dnf install -y dnf5 && \
    dnf5 install -y wget rpm-build make gcc gcc-c++ dkms findutils systemd-devel
# 2. Pobranie Najnowszego Kernela 7.0 (Fedora 43)
RUN mkdir -p /rpms/kernel && \
    dnf5 download --destdir=/rpms/kernel kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-devel
# 3. Oficjalne sterowniki NVIDIA (Unix Driver Archive)
# Pobieramy najnowszą paczkę z nvidia.com omijając RPMFusion
RUN mkdir -p /rpms/nvidia && \
    wget https://us.download.nvidia.com/XFree86/Linux-x86_64/570.43/NVIDIA-Linux-x86_64-570.43.run -O /build/nvidia.run && \
    chmod +x /build/nvidia.run
# Uwaga: Dla systemów ostree (Bazzite) lepiej wyekstrahować pliki paczki .run 
# i zbudować ręcznie DKMS za pomocą skryptu na etapie budowania kontenera budowniczego.
# 4. Moduły specjalne dla Lenovo Legion
RUN dnf5 copr enable -y mrduarte/LenovoLegionLinux && \
    dnf5 download --destdir=/rpms/lenovo python-LenovoLegionLinux dkms-LenovoLegionLinux
# 5. Zbudowanie modułów DKMS (NVIDIA + Lenovo)
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" -p /rpms/kernel/kernel-devel-*.rpm | head -n 1) && \
    echo "Kompilowanie modułów dla Kernela $KERNEL_VERSION..." && \
    # ... skrypt wyciągający pliki źródłowe nvidii i kompilujący moduł dla powyższego kernela ...
    mkdir -p /rpms/kmods && \
    find /var/lib/dkms/ -name "*.ko" -exec cp {} /rpms/kmods/ \;
FROM scratch
COPY --from=builder /rpms/ /rpms/
