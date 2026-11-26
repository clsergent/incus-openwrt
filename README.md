# Incus for ARM64 OpenWrt targets

This repository builds static Incus binaries and APK packages for ARM64 targets.
Common versions and defaults live in `common.env`; hardware-specific settings live
in `targets/*.env` and override common values.

## Targets

- `filogic`: original MediaTek Filogic/MT7988A target (`aarch64_cortex-a53`) with
  Cortex-A73 tuning and an ARMv8.0 Go baseline.
- `rk3582`: Rockchip RK3582 target (`aarch64_generic`) for heterogeneous
  Cortex-A76/A55 systems, using no CPU-specific C tuning and an ARMv8.0 baseline.

Shared versions include Alpine, Go, Incus, eudev, dbus, attr, squashfs-tools, and
xz. Target files may override package architecture, compiler flags, Go ISA,
package signing-key filename, and package description.

## Build locally

```sh
INCUS_SIGN_KEY_FILE=/path/to/private-key.pem ./build.sh rk3582
```

Packages are written to `output/<target>/.`

## GitHub Actions

Choose `filogic` or `rk3582` when running the workflow. Configure the `INCUS_SIGN_KEY` secret with the PEM-encoded APK signing private key. The workflow uploads the generated package set as an artifact.