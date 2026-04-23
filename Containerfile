# Używamy Fedory Rawhide dla najświeższych technologii
FROM fedora:rawhide AS builder

# 1. Instalacja podstawowych narzędzi do kompilacji
RUN dnf install -y dnf5 && \
    dnf5 install -y akmods rpm-build gcc-c++ make systemd-devel findutils

# 2. Włączenie repozytoriów RPMFusion Rawhide
RUN rpm -ivh --nodeps --nosignature https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
                                    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm

# 3. Instalacja Kernela, Nvidii oraz narzędzi DKMS dla Lenovo
RUN dnf5 copr enable -y mrduarte/LenovoLegionLinux && \
    dnf5 install -y kernel-devel akmod-nvidia dkms dkms-lenovolegionlinux

# 4. KOMPILACJA MODUŁÓW (Nvidia przez akmods, Lenovo przez dkms)
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kompiluję moduł Nvidia dla kernela: $KERNEL_VERSION" && \
    akmods --force --kernels "$KERNEL_VERSION" && \
    echo "Kompiluję moduł Lenovo (DKMS)..." && \
    DKMS_VER=$(ls /usr/src | grep lenovolegionlinux | sed 's/lenovolegionlinux-//') && \
    dkms build -m lenovolegionlinux -v $DKMS_VER -k "$KERNEL_VERSION" && \
    mkdir -p /rpms/kmods && \
    find /var/lib/dkms/lenovolegionlinux/$DKMS_VER/$KERNEL_VERSION/ -name "*.ko" -exec cp {} /rpms/kmods/ \;

# --- ETAP 2: Wyciągnięcie gotowych plików ---
FROM scratch
COPY --from=builder /var/cache/akmods/*/*.rpm /rpms/
COPY --from=builder /rpms/kmods/ /rpms/kmods/
