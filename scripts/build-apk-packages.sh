#!/bin/sh
set -e

INCUS_VERSION="${INCUS_VERSION:?INCUS_VERSION not set}"
INCUS_SIGN_KEY_FILE="${INCUS_SIGN_KEY_FILE:?INCUS_SIGN_KEY_FILE not set}"
APK_ARCH="${APK_ARCH:?APK_ARCH not set}"
APK_SIGNING_KEY_NAME="${APK_SIGNING_KEY_NAME:?APK_SIGNING_KEY_NAME not set}"
APK_REVISION="${APK_REVISION:-0}"
TARGET_DESCRIPTION="${TARGET_DESCRIPTION:-ARM64}"
OUT_DIR="${OUT_DIR:-/output}"
PKG_DIR="${PKG_DIR:-$OUT_DIR/pkg}"
INCUS_INITD="${INCUS_INITD:-incus.initd}"
VER="${INCUS_VERSION}-r${APK_REVISION}"

mkdir -p "$PKG_DIR"
chmod +x "$OUT_DIR/stage/attr/usr/bin/setfattr" "$OUT_DIR/stage/xz/usr/bin/xz" "$OUT_DIR/stage/squashfs-tools/unsquashfs"
ATTR_VER="$("$OUT_DIR/stage/attr/usr/bin/setfattr" --version | awk '{print $2}')-r${APK_REVISION}"
XZ_VER="$("$OUT_DIR/stage/xz/usr/bin/xz" --version | head -1 | awk '{print $NF}')-r${APK_REVISION}"
SQUASHFS_VER="$("$OUT_DIR/stage/squashfs-tools/unsquashfs" -version | head -1 | awk '{print $3}')-r${APK_REVISION}"

root="$PKG_DIR/root-incus-static"
install -Dm755 "$OUT_DIR/incus" "$root/usr/bin/incus"
install -Dm755 "$OUT_DIR/incusd" "$root/usr/sbin/incusd"
install -Dm755 "$INCUS_INITD" "$root/etc/init.d/incus"

root="$PKG_DIR/root-attr-static"
mkdir -p "$root/usr/bin"
cp "$OUT_DIR/stage/attr/usr/bin/"* "$root/usr/bin/"

root="$PKG_DIR/root-xz-static"
install -Dm755 "$OUT_DIR/stage/xz/usr/bin/xz" "$root/usr/libexec/xz-lzmautils"
mkdir -p "$root/usr/bin"
for name in xz lzcat lzma unlzma unxz xzcat; do
    ln -s /usr/libexec/xz-lzmautils "$root/usr/bin/$name"
done

root="$PKG_DIR/root-squashfs-mksquashfs"
install -Dm755 "$OUT_DIR/stage/squashfs-tools/mksquashfs" "$root/usr/sbin/mksquashfs"
ln -s mksquashfs "$root/usr/sbin/sqfstar"

root="$PKG_DIR/root-squashfs-unsquashfs"
install -Dm755 "$OUT_DIR/stage/squashfs-tools/unsquashfs" "$root/usr/sbin/unsquashfs"
ln -s unsquashfs "$root/usr/sbin/sqfscat"

cd "$PKG_DIR"
apk mkpkg -F root-incus-static \
    --info name:incus-static --info version:"$VER" --info "arch:$APK_ARCH" \
    --info "description:Incus container and VM manager (static build for $TARGET_DESCRIPTION)" \
    --info license:Apache-2.0 --info url:https://linuxcontainers.org/incus/ \
    --info "depends:attr xz squashfs-tools-unsquashfs" -o "incus-static-$VER.apk"

apk mkpkg -F root-attr-static \
    --info name:attr-static --info version:"$ATTR_VER" --info "arch:$APK_ARCH" \
    --info "description:Static attr/getfattr/setfattr for Incus, alternative to attr" \
    --info license:LGPL-2.1-or-later --info replaces:attr \
    --info "provides:attr=$ATTR_VER cmd:attr=$ATTR_VER cmd:getfattr=$ATTR_VER cmd:setfattr=$ATTR_VER" -o "attr-static-$ATTR_VER.apk"

apk mkpkg -F root-xz-static \
    --info name:xz-static --info version:"$XZ_VER" --info "arch:$APK_ARCH" \
    --info "description:Static xz for Incus, alternative to xz" \
    --info license:0BSD --info "replaces:xz xz-utils" \
    --info "provides:xz=$XZ_VER xz-utils=$XZ_VER cmd:xz=$XZ_VER cmd:lzcat=$XZ_VER cmd:lzma=$XZ_VER cmd:unlzma=$XZ_VER cmd:unxz=$XZ_VER cmd:xzcat=$XZ_VER" -o "xz-static-$XZ_VER.apk"

apk mkpkg -F root-squashfs-mksquashfs \
    --info name:squashfs-tools-mksquashfs-static --info version:"$SQUASHFS_VER" --info "arch:$APK_ARCH" \
    --info "description:Static mksquashfs/sqfstar for Incus" \
    --info license:GPL-2.0-or-later --info replaces:squashfs-tools-mksquashfs \
    --info "provides:squashfs-tools-mksquashfs=$SQUASHFS_VER cmd:mksquashfs=$SQUASHFS_VER cmd:sqfstar=$SQUASHFS_VER" -o "squashfs-tools-mksquashfs-static-$SQUASHFS_VER.apk"

apk mkpkg -F root-squashfs-unsquashfs \
    --info name:squashfs-tools-unsquashfs-static --info version:"$SQUASHFS_VER" --info "arch:$APK_ARCH" \
    --info "description:Static unsquashfs/sqfscat for Incus" \
    --info license:GPL-2.0-or-later --info replaces:squashfs-tools-unsquashfs \
    --info "provides:squashfs-tools-unsquashfs=$SQUASHFS_VER cmd:unsquashfs=$SQUASHFS_VER cmd:sqfscat=$SQUASHFS_VER" -o "squashfs-tools-unsquashfs-static-$SQUASHFS_VER.apk"

apk mkndx --allow-untrusted --sign-key "$INCUS_SIGN_KEY_FILE" -o packages.adb ./*.apk
openssl ec -in "$INCUS_SIGN_KEY_FILE" -pubout -out "$APK_SIGNING_KEY_NAME" 2>/dev/null
