#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./scripts/install-box64.sh" >&2
    exit 1
fi

if command -v box64 >/dev/null 2>&1; then
    echo "Box64 already installed: $(command -v box64)"
    box64 --version || true
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This helper currently supports Debian/Ubuntu with apt-get." >&2
    echo "Install Box64 manually from https://github.com/ptitSeb/box64" >&2
    exit 1
fi

apt-get update
apt-get install -y git cmake make gcc g++ libc6-dev

WORKDIR="${BOX64_BUILD_DIR:-/tmp/box64-build}"
rm -rf "$WORKDIR"
git clone --depth 1 https://github.com/ptitSeb/box64 "$WORKDIR"
cmake -S "$WORKDIR" -B "$WORKDIR/build" -D ARM_DYNAREC=ON -D CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$WORKDIR/build" -j"$(nproc)"
cmake --install "$WORKDIR/build"

if command -v systemctl >/dev/null 2>&1; then
    systemctl restart systemd-binfmt 2>/dev/null || true
fi

box64 --version || true

