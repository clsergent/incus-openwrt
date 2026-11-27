# Incus for ARM64 OpenWrt targets

This repository builds static Incus binaries and one standalone APK for each
supported ARM64 target.

The APK version is derived from `INCUS_VERSION` and `APK_REVISION` in
`targets/common.env`.

## Targets

- `filogic`: MediaTek Filogic/MT7988A (`aarch64_cortex-a53`), tuned for Cortex-A73.
- `rk3582`: Rockchip RK3582 (`aarch64_generic`), using an ARMv8.0 baseline.

## Build locally

```sh
./build.sh rk3582
```

The standalone APK is written to:

```text
output/<target>/pkg/incus-openwrt-<target>-<INCUS_VERSION>-r<APK_REVISION>.apk
```
