# akmods-nvidia-custom

![Build Status](https://github.com/Vyzygota/akmods-nvidia-custom/actions/workflows/build.yml/badge.svg)

Automated factory that compiles the latest stable Linux kernel and NVIDIA drivers into RPM packages, ready to be consumed by [BleedingEdgeBazzite](https://github.com/Vyzygota/BleedingEdgeBazzite).

## What it builds

| Component | Source | Notes |
|-----------|--------|-------|
| Linux kernel | kernel.org (latest stable) | Built from `@kernel-vanilla` COPR |
| NVIDIA drivers | `ublue-os/bazzite` stable release matching the base image | Compiled from `.run` installer; version must match the driver shipped in the base image |
| evdi | `DisplayLink/evdi` latest release | DisplayLink kernel module |
| LenovoLegionLinux | `johnfanv2/LenovoLegionLinux` latest release | Fan/power control for Lenovo Legion (a release tag, not the moving `main` branch) |
| Dummy RPM | local | Satisfies Bazzite dependency checks |

## How it works

**Cyber-Spider** — the first job in the pipeline — scrapes its sources on every run, always picking the latest stable version (no pinned numbers):

- `fedoraproject.org` for the latest Fedora release **for which Bazzite publishes a `stable-<Fedora>` base image** (if Fedora GA comes first, it stays on the previous release until Bazzite catches up)
- the `bazzite-deck-nvidia:stable-<Fedora>` image label and the matching `ublue-os/bazzite` release for the NVIDIA driver version
- `kernel.org` / `@kernel-vanilla` COPR for the latest stable kernel available for that Fedora
- the latest release of `DisplayLink/evdi` and `johnfanv2/LenovoLegionLinux`

For every component the factory builds, the spider also collects the **source address** (COPR repo for the kernel, the NVIDIA `.run` URL, the evdi and LenovoLegionLinux release tarballs), checks that each one responds, and aborts the run *before* the expensive build if any source is missing. The addresses are written to the job summary as a table and passed to the build as `NVIDIA_URL` / `EVDI_URL` / `LLL_URL` build-args, so the `Containerfile` no longer composes URLs on its own (the full manifest is also exposed as the `sources` job output).

It then compares the detected versions (including the LenovoLegionLinux tag) against `versions.lock`. If nothing changed, the build is skipped entirely. If any version is new, the factory compiles everything from source, pushes the OCI artifact to GHCR, updates `versions.lock`, and triggers a BleedingEdgeBazzite rebuild.

If the spider itself fails on `main` (a source is missing, an API is down), it sends a Discord alarm through the same `DISCORD_WEBHOOK` secret as the build job: the step that failed, the reason (when the spider knows it) and a link to the run. The build job keeps its own alarm.

Only one factory run executes at a time (`concurrency`): a run triggered while another one is building waits instead of racing for `:latest` and the `versions.lock` commit; a running build is never cancelled.

The spider also watches the Watchdog in BleedingEdgeBazzite: GitHub disables scheduled workflows in repositories without activity for 60 days (`disabled_inactivity`), so every run checks the Watchdog's state and re-enables it when GitHub disabled it that way (a manual disable is left alone). The result is reported on Discord.

Runs started from a branch (e.g. a PR) perform the full build **without** pushing the image, updating `versions.lock`, notifying BEB or raising the Discord alarm — only `main` publishes.

```
Cyber-Spider detects versions + collects/verifies source addresses
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
