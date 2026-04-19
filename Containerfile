# Używamy Fedory Rawhide, bo odpowiada ona kernelowi fc45
FROM fedora:rawhide AS builder

# 1. Instalacja podstawowych narzędzi do kompilacji
RUN dnf install -y akmods rpm-build wget gcc-c++ make systemd-devel

# 2. Włączenie repozytoriów RPMFusion (skąd weźmiemy źródła Nvidii)
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
                   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm

# 3. Pobranie Twojego konkretnego kernela (kernel-devel i headers są niezbędne do kompilacji!)
WORKDIR /tmp/kernel
RUN wget https://fr2.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/k/kernel-devel-7.0.0-62.fc45.x86_64.rpm \
         https://fr2.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/k/kernel-core-7.0.0-62.fc45.x86_64.rpm \
         https://fr2.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/k/kernel-modules-7.0.0-62.fc45.x86_64.rpm \
         https://fr2.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/k/kernel-modules-core-7.0.0-62.fc45.x86_64.rpm \
         https://fr2.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/k/kernel-7.0.0-62.fc45.x86_64.rpm

# 4. Instalacja pobranego kernela i źródeł Nvidii
RUN dnf install -y ./*.rpm
RUN dnf install -y akmod-nvidia

# 5. WŁAŚCIWA KOMPILACJA - wymuszamy budowę dla kernela 7.0.0
# UWAGA: To potrwa kilka minut.
RUN akmods --force --kernels 7.0.0-62.fc45.x86_64 --akmod nvidia

# --- ETAP 2: Wyciągnięcie gotowych RPM-ów ---
# BlueBuild oczekuje, że obraz akmods będzie po prostu pustym "pudełkiem" (scratch)
# zawierającym tylko i wyłącznie gotowe pakiety .rpm w folderze /rpms/
FROM scratch
COPY --from=builder /var/cache/akmods/nvidia/*.rpm /rpms/
