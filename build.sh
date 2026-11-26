#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
IN_CONTAINER="${BUILD_IN_CONTAINER:-0}"
TARGET="${BUILD_TARGET:-${1:-filogic}}"

if [ "$IN_CONTAINER" = 1 ]; then
    CONFIG_DIR=/config
    SCRIPT_DIR=/scripts
else
    CONFIG_DIR="$SCRIPT_DIR"
fi

TARGET_FILE="$CONFIG_DIR/targets/$TARGET.env"
[ -f "$TARGET_FILE" ] || {
    echo "Unknown target '$TARGET'. Available targets:" >&2
    for file in "$CONFIG_DIR"/targets/*.env; do
        [ -f "$file" ] && echo "  $(basename "$file" .env)" >&2
    done
    exit 2
}

set -a
. "$CONFIG_DIR/targets/common.env"
. "$TARGET_FILE"
set +a

if [ "$IN_CONTAINER" = 1 ]; then
    mkdir -p "$OUT_DIR"
    /scripts/install-deps.sh
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz" -O /tmp/go.tar.gz
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    export PATH="/usr/local/go/bin:$PATH"

    /scripts/build-eudev.sh
    /scripts/build-dbus.sh
    mkdir -p /usr/local/include
    /scripts/build-incus.sh
    /scripts/build-attr.sh
    /scripts/build-squashfs.sh
    /scripts/build-xz.sh
    /scripts/verify-static.sh

    export INCUS_SIGN_KEY_FILE=/run/secrets/incus_sign_key
    apk add --no-cache openssl
    /scripts/build-apk-packages.sh
    exit 0
fi

INCUS_SIGN_KEY_FILE="${INCUS_SIGN_KEY_FILE:?Set INCUS_SIGN_KEY_FILE to the APK signing private-key path}"
[ -r "$INCUS_SIGN_KEY_FILE" ] || {
    echo "Cannot read signing key: $INCUS_SIGN_KEY_FILE" >&2
    exit 1
}

KEY_DIR="$(CDPATH= cd -- "$(dirname -- "$INCUS_SIGN_KEY_FILE")" && pwd)"
INCUS_SIGN_KEY_FILE="$KEY_DIR/$(basename -- "$INCUS_SIGN_KEY_FILE")"

OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/output/$TARGET}"
mkdir -p "$OUTPUT_DIR"

docker buildx build --load --tag incus-openwrt-builder .
docker run --rm \
  --platform linux/arm64 \
  -e BUILD_IN_CONTAINER=1 \
  -e BUILD_TARGET="$TARGET" \
  -v "$OUTPUT_DIR:/output" \
  --mount "type=bind,src=$INCUS_SIGN_KEY_FILE,dst=/run/secrets/incus_sign_key,readonly" \
  incus-openwrt-builder

echo "APK packages for $TARGET in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"