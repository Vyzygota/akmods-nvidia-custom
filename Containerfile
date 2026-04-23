FROM fedora:rawhide AS builder

# 1. Instalacja dnf5 i dkms (narzędzia bazowe)
RUN dnf install -y dnf5 && \
    dnf5 install -y akmods rpm-build gcc-c++ make systemd-devel findutils dkms

# 2. Ręczne dopisanie repozytoriów (ZAMIAST instalacji RPM - to nas uodparnia na awarie mirrorów)
RUN printf "[rpmfusion-free-rawhide]\nname=RPM Fusion Rawhide Free\nmetalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-rawhide&arch=\$basearch\nenabled=1\ngpgcheck=0\n" > /etc/yum.repos.d/rpmfusion-free-rawhide.repo && \
    printf "[rpmfusion-nonfree-rawhide]\nname=RPM Fusion Rawhide Nonfree\nmetalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-rawhide&arch=\$basearch\nenabled=1\ngpgcheck=0\n" > /etc/yum.repos.d/rpmfusion-nonfree-rawhide.repo

# 3. Instalacja pełnego Kernela i Sterowników (Ważne: kernel-modules i kernel-core uciszą akmods)
RUN dnf5 copr enable -y mrduarte/LenovoLegionLinux && \
    dnf5 install -y kernel kernel-core kernel-modules kernel-devel akmod-nvidia dkms dkms-LenovoLegionLinux

# 4. Kompilacja
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    akmods --force --kernels "$KERNEL_VERSION" && \
    DKMS_FOLDER=$(ls /usr/src | grep -i lenovo | head -n 1) && \
    DKMS_NAME=${DKMS_FOLDER%-*} && \
    DKMS_VER=${DKMS_FOLDER#*-} && \
    dkms build -m $DKMS_NAME -v $DKMS_VER -k "$KERNEL_VERSION" && \
    mkdir -p /rpms/kmods && \
    find /var/lib/dkms/$DKMS_NAME/$DKMS_VER/$KERNEL_VERSION/ -name "*.ko" -exec cp {} /rpms/kmods/ \;

FROM scratch
COPY --from=builder /var/cache/akmods/*/*.rpm /rpms/
COPY --from=builder /rpms/kmods/ /rpms/kmods/
