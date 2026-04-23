FROM fedora:rawhide AS builder

# 1. Narzędzia (dodajemy dkms dla Lenovo)
RUN dnf install -y dnf5 && \
    dnf5 install -y akmods rpm-build gcc-c++ make systemd-devel findutils dkms

# 2. Repo RPMFusion (bez zmian)
RUN rpm -ivh --nodeps --nosignature https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
                                    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm

# 3. Kernel i Sterowniki (dodajemy pełny komplet kernela, żeby akmods nie pyskował)
RUN dnf5 copr enable -y mrduarte/LenovoLegionLinux && \
    dnf5 install -y kernel kernel-core kernel-modules kernel-devel akmod-nvidia dkms-LenovoLegionLinux

# 4. Kompilacja (Nvidia leci automatem, Lenovo wyciągamy ręcznie)
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
