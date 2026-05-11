# 🕷️ akmods-nvidia-custom (Cyber-Pająk Edition)

![Build Status](https://github.com/Vyzygota/akmods-nvidia-custom/actions/workflows/build.yml/badge.svg)
![Latest Release](https://img.shields.io/github/v/release/Vyzygota/akmods-nvidia-custom?color=neon&style=flat-square)

Automatyczna "Fabryka" najnowszego uzbrojenia dla systemów Fedora Atomic (Bazzite, uBlue, Fedora Silverblue). Projekt ten wykorzystuje **Cyber-Pająka Zwiadowcę**, który codziennie przeszukuje sieć w poszukiwaniu najświeższych komponentów, aby dostarczyć gotowe moduły jądra zanim pojawią się w oficjalnych repozytoriach.

## 🚀 Założenia Projektu "All Latest"

Ten projekt nie uznaje kompromisów. Zawsze celujemy w najnowsze stabilne wersje:
*   **Fedora**: Najwyższa dostępna wersja (obecnie Fedora 44).
*   **Linux Kernel**: Absolutnie najnowsza wersja prosto z `kernel.org`. Śledzimy wydania Linusa Torvaldsa (Mainline/RC) oraz najnowsze wydania stabilne (Stable), wykorzystując repozytoria `@kernel-vanilla` jako źródło paczek.
*   **NVIDIA Drivers**: Najnowsze sterowniki `.run` prosto od producenta (seria 595.x+).

## 🛠️ Co znajduje się wewnątrz?

1.  **NVIDIA Kmods**: Kompilacja modułów z autorskim "Wytrychem" (Lockpick), który pozwala na budowanie sterowników NVIDIA dla Kernela 7.0+ przy użyciu GCC 16, wyciszając restrykcje kompilatora i naprawiając błędy MITIGATION_RETHUNK.
2.  **LenovoLegionLinux**: Najnowsze moduły sterownika dla laptopów Lenovo Legion, zintegrowane bezpośrednio z najnowszym jądrem.
3.  **Dummy RPM (kernel-nvidia)**: Specjalna paczka oszukująca zależności systemowe Bazzite/uBlue, pozwalająca na używanie customowych modułów bez konfliktów z menedżerem pakietów.

## 🏗️ Architektura

*   **Pajączek Zwiadowca**: Skrypt GitHub Actions, który dynamicznie scrapuje:
    *   `kernel.org` (wersja jądra)
    *   `download.nvidia.com` (wersja sterownika)
    *   `fedoraproject.org` (wersja dystrybucji)
*   **Container Builder**: Wykorzystuje `dnf5` i repozytoria Copr `@kernel-vanilla/fedora` do przygotowania czystego środowiska budowania (z usuwaniem domyślnych jąder Fedory w celu uniknięcia konfliktów).
*   **Artifact Export**: Gotowe paczki `.rpm` oraz moduły `.ko` są wypychane do GitHub Container Registry (GHCR) jako warstwy obrazu `scratch`.

## 📦 Jak używać?

Paczki są dostępne w obrazie:
`ghcr.io/vyzygota/akmods-nvidia-custom:latest`

Możesz je wyciągnąć za pomocą:
```bash
docker run --rm -v $(pwd)/rpms:/out ghcr.io/vyzygota/akmods-nvidia-custom:latest cp -r /rpms/. /out/
```

## ⚠️ Ostrzeżenie

To jest projekt "Bleeding Edge". Używasz go na własną odpowiedzialność. Jeśli Pajączek melduje o pożarze w fabryce, oznacza to, że nowe wersje GCC lub Kernela wprowadziły zmiany wymagające nowej wersji "Wytrycha".

---
*Created with ❤️ by Vyzygota & Cyber-Pająk*