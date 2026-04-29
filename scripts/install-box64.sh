#!/usr/bin/env bash
set -Eeuo pipefail

BOX64_REF="${BOX64_REF:-v0.4.2}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root for dependency installation and final install:" >&2
    echo "  sudo BOX64_REF=$BOX64_REF ./scripts/install-box64.sh" >&2
    echo "The script builds as SUDO_USER when available and uses root only for apt/cmake install." >&2
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

if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    BUILD_USER="$SUDO_USER"
else
    BUILD_USER="$(id -un)"
fi

mkdir -p "$WORKDIR"
chown "$BUILD_USER":"$BUILD_USER" "$WORKDIR"

sudo -u "$BUILD_USER" git clone --branch "$BOX64_REF" --depth 1 https://github.com/ptitSeb/box64 "$WORKDIR/src"
BOX64_COMMIT="$(sudo -u "$BUILD_USER" git -C "$WORKDIR/src" rev-parse HEAD)"
echo "Building Box64 ref $BOX64_REF at commit $BOX64_COMMIT"
sudo -u "$BUILD_USER" cmake -S "$WORKDIR/src" -B "$WORKDIR/build" -D ARM_DYNAREC=ON -D CMAKE_BUILD_TYPE=RelWithDebInfo
sudo -u "$BUILD_USER" cmake --build "$WORKDIR/build" -j"$(nproc)"
cmake --install "$WORKDIR/build"

if command -v systemctl >/dev/null 2>&1; then
    systemctl restart systemd-binfmt 2>/dev/null || true
fi

box64 --version || true
