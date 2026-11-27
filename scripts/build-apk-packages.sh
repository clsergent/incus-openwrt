#!/bin/sh
set -eu

INCUS_VERSION="${INCUS_VERSION:?INCUS_VERSION not set}"
APK_ARCH="${APK_ARCH:?APK_ARCH not set}"
TARGET="${BUILD_TARGET:-${TARGET:-unknown}}"
APK_REVISION="${APK_REVISION:-0}"
TARGET_DESCRIPTION="${TARGET_DESCRIPTION:-ARM64}"
OUT_DIR="${OUT_DIR:-/output}"
PKG_DIR="${PKG_DIR:-$OUT_DIR/pkg}"
INCUS_INITD="${INCUS_INITD:-/build/incus.initd}"
VER="${INCUS_VERSION}-r${APK_REVISION}"
PKG_NAME="incus-openwrt-${TARGET}-${VER}.apk"

[ "$TARGET" != unknown ] || {
    echo "BUILD_TARGET or TARGET must be set" >&2
    exit 1
}

mkdir -p "$PKG_DIR"
ROOT="$PKG_DIR/root-incus-openwrt"

# Remove any package root or APKs left by a previous build.
rm -rf "$ROOT"
find "$PKG_DIR" -maxdepth 1 -type f -name '*.apk' -delete

install -Dm755 "$OUT_DIR/incus" "$ROOT/usr/bin/incus"
install -Dm755 "$OUT_DIR/incusd" "$ROOT/usr/sbin/incusd"
install -Dm755 "$INCUS_INITD" "$ROOT/etc/init.d/incus"

mkdir -p "$ROOT/usr/bin"
cp -a "$OUT_DIR/stage/attr/usr/bin/." "$ROOT/usr/bin/"

install -Dm755 "$OUT_DIR/stage/xz/usr/bin/xz" \
    "$ROOT/usr/libexec/xz-lzmautils"
for name in xz lzcat lzma unlzma unxz xzcat; do
    ln -sfn /usr/libexec/xz-lzmautils "$ROOT/usr/bin/$name"
done

install -Dm755 "$OUT_DIR/stage/squashfs-tools/mksquashfs" \
    "$ROOT/usr/sbin/mksquashfs"
ln -sfn mksquashfs "$ROOT/usr/sbin/sqfstar"

install -Dm755 "$OUT_DIR/stage/squashfs-tools/unsquashfs" \
    "$ROOT/usr/sbin/unsquashfs"
ln -sfn unsquashfs "$ROOT/usr/sbin/sqfscat"

cd "$PKG_DIR"
apk mkpkg -F root-incus-openwrt \
    --info "name:incus-openwrt-${TARGET}" \
    --info "version:${VER}" \
    --info "arch:${APK_ARCH}" \
    --info "description:Incus and bundled static utilities for ${TARGET_DESCRIPTION}" \
    --info license:Apache-2.0 \
    --info url:https://linuxcontainers.org/incus/ \
    -o "$PKG_NAME"

test -s "$PKG_NAME"
echo "Built standalone APK: $PKG_DIR/$PKG_NAME"