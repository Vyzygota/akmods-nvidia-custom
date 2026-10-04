# akmods-nvidia-custom

![Build Status](https://github.com/Vyzygota/akmods-nvidia-custom/actions/workflows/build.yml/badge.svg)

Automated factory that compiles the latest stable Linux kernel and NVIDIA drivers into RPM packages, ready to be consumed by [BleedingEdgeBazzite](https://github.com/Vyzygota/BleedingEdgeBazzite).

## What it builds

| Component | Source | Notes |
|-----------|--------|-------|
| Linux kernel | kernel.org (latest stable) | Built from `@kernel-vanilla` COPR |
| NVIDIA drivers | `ublue-os/bazzite` stable release matching the base image | Compiled from `.run` installer; version must match the driver shipped in the base image |
| LenovoLegionLinux | upstream | Fan/power control for Lenovo Legion |
| Dummy RPM | local | Satisfies Bazzite dependency checks |

## How it works

**Cyber-Spider** — the first job in the pipeline — scrapes its sources on every run, always picking the latest stable version (no pinned numbers):

- `fedoraproject.org` for the latest Fedora release **for which Bazzite publishes a `stable-<Fedora>` base image** (if Fedora GA comes first, it stays on the previous release until Bazzite catches up)
- the `bazzite-deck-nvidia:stable-<Fedora>` image label and the matching `ublue-os/bazzite` release for the NVIDIA driver version
- `kernel.org` / `@kernel-vanilla` COPR for the latest stable kernel available for that Fedora

It then compares the detected versions against `versions.lock`. If nothing changed, the build is skipped entirely. If any version is new, the factory compiles everything from source, pushes the OCI artifact to GHCR, updates `versions.lock`, and triggers a BleedingEdgeBazzite rebuild.

```
Cyber-Spider detects versions
    └─► Compare with versions.lock
            ├─► No changes → stop, nothing to do
            └─► New version found → compile → push OCI → update lock → trigger BEB
```

## Output

Packages are published as an OCI image:

```
ghcr.io/vyzygota/akmods-nvidia-custom:latest
```

Artifacts inside the image:

```
/rpms/kernel/   — kernel, kernel-core, kernel-modules RPMs
/rpms/kmods/    — NVIDIA .ko module files
/rpms/dummy/    — kernel-nvidia dummy RPM
```

## Consuming the packages

```bash
docker run --rm -v $(pwd)/rpms:/out \
  ghcr.io/vyzygota/akmods-nvidia-custom:latest \
  cp -r /rpms/. /out/
```

## Disclaimer

This is a bleeding-edge project. New GCC or kernel releases occasionally break the build — that is expected. When the factory fails, Discord gets notified. If you rely on this image, watch the build badge above.

---

*Built by Vyzygota with [Claude Code](https://claude.ai/code) (Anthropic)*
