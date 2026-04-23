# Używamy Fedory Rawhide dla najświeższych technologii
FROM fedora:rawhide AS builder

# 1. Instalacja podstawowych narzędzi do kompilacji i obsługa dnf5
RUN dnf install -y dnf5 && \
    dnf5 install -y akmods rpm-build gcc-c++ make systemd-devel findutils

# 2. Włączenie repozytoriów RPMFusion Rawhide (omijamy sprawdzanie kluczy dla samych plików konfiguracyjnych)
RUN dnf5 install --nogpgcheck -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
                                 https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm

# 3. Instalacja Kernela, sterowników NVIDIA i Lenovo Legion Linux
# Instalujemy akmod-nvidia (z RPMFusion) oraz akmod-lenovolegionlinux (z COPR)
RUN dnf5 copr enable -y mrduarte/LenovoLegionLinux && \
    dnf5 install -y kernel-devel akmod-nvidia akmod-lenovolegionlinux

# 4. KOMPILACJA MODUŁÓW
# Wyciągamy wersję kernela i budujemy WSZYSTKIE zainstalowane akmody
RUN KERNEL_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-devel | head -n 1) && \
    echo "Kompiluję moduły dla kernela: $KERNEL_VERSION" && \
    akmods --force --kernels "$KERNEL_VERSION" && \
    # Sprawdzamy, czy pliki .rpm powstały (dla pewności w logach)
    find /var/cache/akmods/ -name "*.rpm"

# --- ETAP 2: Wyciągnięcie gotowych RPM-ów ---
FROM scratch

# Kopiujemy wszystkie skompilowane paczki (Nvidia i Lenovo) do folderu /rpms
# Dzięki temu moduł 'copy' w Twoim głównym recipe.yml zabierze obie na raz
COPY --from=builder /var/cache/akmods/*/*.rpm /rpms/
