#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${SYNOSNAP_VERSION:-0.12.10}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

if [ ! -d "/usr/src/synosnap-$VERSION" ]; then
    echo "Missing /usr/src/synosnap-$VERSION" >&2
    exit 1
fi

dkms add -m synosnap -v "$VERSION" 2>/dev/null || true
dkms build -m synosnap -v "$VERSION"
dkms install -m synosnap -v "$VERSION"
modprobe synosnap
dkms status "synosnap/$VERSION" || true
lsmod | grep synosnap || true

