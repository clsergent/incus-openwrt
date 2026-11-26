#!/bin/sh
set -e

INCUS_VERSION="${INCUS_VERSION:?INCUS_VERSION not set}"
GOARCH="${GOARCH:?GOARCH not set}"
GOARM64="${GOARM64:?GOARM64 not set}"
OUT_DIR="${OUT_DIR:-/output}"
mkdir -p "$OUT_DIR"

wget -q "https://github.com/lxc/incus/archive/refs/tags/v${INCUS_VERSION}.tar.gz"
tar zxf "v${INCUS_VERSION}.tar.gz"
mv "incus-${INCUS_VERSION}" incus
cd incus

export CFLAGS="$ARCH_CFLAGS"
make deps

export GOARCH GOARM64
export CGO_ENABLED=1
export CGO_CFLAGS="-I/root/go/deps/raft/include/ -I/root/go/deps/cowsql/include/ $ARCH_CFLAGS"
export CGO_CPPFLAGS="-I/usr/include"
export CGO_LDFLAGS="-L/root/go/deps/raft/.libs -L/root/go/deps/cowsql/.libs/ -L/usr/lib -static -Wl,--allow-multiple-definition -lcowsql -lraft -luv -llz4 -lintl -lseccomp -ldbus-1 -lexpat -lcap -ludev -lsqlite3 -lz -lpthread"
export LD_LIBRARY_PATH="/root/go/deps/raft/.libs/:/root/go/deps/cowsql/.libs/"
export CGO_LDFLAGS_ALLOW="(-Wl,-wrap,pthread_create)|(-Wl,-z,now)"

go build -buildvcs=false -trimpath -tags libsqlite3 -ldflags="-s -w -extldflags=-static" -o "$OUT_DIR/incusd" ./cmd/incusd
go build -buildvcs=false -trimpath -tags libsqlite3 -ldflags="-s -w -extldflags=-static" -o "$OUT_DIR/incus" ./cmd/incus
