# Używamy Fedory Rawhide, która ma najświeższe kernele
FROM fedora:rawhide AS builder

# 1. Instalacja podstawowych narzędzi do kompilacji
RUN dnf install -y akmods rpm-build gcc-c++ make systemd-devel findutils

# 2. Włączenie repozytoriów RPMFusion (skąd weźmiemy źródła Nvidii)
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
                   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm

# 3. Instalacja najnowszego kernela i paczki akmod-nvidia
# DNF automatycznie pobierze najświeższe wersje z repozytorium Rawhide
RUN dnf install -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-devel akmod-nvidia

# 4. WŁAŚCIWA KOMPILACJA - dynamicznie wykrywamy wersję
# Komenda rpm wyciąga dokładny numer wersji zainstalowanego pakietu kernel-devel
# i podstawia go pod zmienną $KERNEL_VERSION, która trafia do akmods.
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kompiluję sterownik dla kernela: $KERNEL_VERSION" && \
    akmods --force --kernels "$KERNEL_VERSION" --kmod nvidia

# --- ETAP 2: Wyciągnięcie gotowych RPM-ów ---
# BlueBuild oczekuje, że obraz akmods będzie po prostu pustym "pudełkiem" (scratch)
# zawierającym tylko i wyłącznie gotowe pakiety .rpm w folderze /rpms/
FROM scratch
COPY --from=builder /var/cache/akmods/nvidia/*.rpm /rpms/
