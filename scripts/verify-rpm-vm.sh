#!/usr/bin/env bash
set -Eeuo pipefail

RPM_PATH=""
DO_INSTALL=0
DO_UNINSTALL=0
START_SERVICE=0

usage() {
    cat <<'EOF'
Usage:
  ./scripts/verify-rpm-vm.sh
  ./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
  ./scripts/verify-rpm-vm.sh --install --start-service --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
  ./scripts/verify-rpm-vm.sh --uninstall

Run only in a disposable ARM64 RPM-based VM or spare test host.

Default mode is read-only. Installation and uninstall checks require explicit
flags because they change system packages, DKMS state, and systemd state.
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "OK: command found: $1"
        return 0
    fi
    echo "WARN: command missing: $1"
    return 1
}

run() {
    echo
    echo "+ $*"
    "$@"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --rpm)
            [ "$#" -ge 2 ] || die "--rpm requires a path"
            RPM_PATH="$2"
            shift 2
            ;;
        --install)
            DO_INSTALL=1
            shift
            ;;
        --uninstall)
            DO_UNINSTALL=1
            shift
            ;;
        --start-service)
            START_SERVICE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64) ;;
    *) die "This verifier is for ARM64/aarch64 RPM VMs. Current architecture: $ARCH" ;;
esac

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    ID="unknown"
    VERSION_ID="unknown"
fi

PKG_MANAGER=""
if command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
fi

echo "System:"
echo "  arch=$ARCH"
echo "  os=${PRETTY_NAME:-$ID $VERSION_ID}"
echo "  kernel=$(uname -r)"
echo "  package_manager=${PKG_MANAGER:-missing}"

echo
echo "Preflight:"
check_cmd rpm || true
check_cmd systemctl || true
check_cmd dkms || true
check_cmd gcc || true
check_cmd make || true
check_cmd modprobe || true
[ -n "$PKG_MANAGER" ] && echo "OK: package manager found: $PKG_MANAGER" || echo "WARN: dnf or yum not found"

if [ "$DO_INSTALL" -eq 1 ] || [ "$DO_UNINSTALL" -eq 1 ]; then
    need_cmd rpm
    need_cmd systemctl
    need_cmd dkms
    need_cmd gcc
    need_cmd make
    need_cmd modprobe
    [ -n "$PKG_MANAGER" ] || die "dnf or yum is required for install or uninstall mode."
fi

if [ ! -e "/lib/modules/$(uname -r)/build" ]; then
    echo "WARN: kernel headers are missing: /lib/modules/$(uname -r)/build"
    echo "      Install the matching kernel-devel package before rpm install."
else
    echo "OK: kernel headers present."
fi

if [ -x /usr/local/bin/box64 ]; then
    BOX64_BIN=/usr/local/bin/box64
elif [ -x /usr/bin/box64 ]; then
    BOX64_BIN=/usr/bin/box64
else
    BOX64_BIN=""
fi

if [ -n "$BOX64_BIN" ]; then
    echo "OK: box64 found at $BOX64_BIN"
    "$BOX64_BIN" --version || true
else
    echo "WARN: box64 not found at /usr/local/bin/box64 or /usr/bin/box64"
fi

if command -v getenforce >/dev/null 2>&1; then
    echo "SELinux: $(getenforce)"
else
    echo "SELinux: getenforce not available"
fi

if [ "$DO_INSTALL" -eq 1 ]; then
    [ -n "$RPM_PATH" ] || die "--install requires --rpm <path>"
    [ -f "$RPM_PATH" ] || die "RPM path does not exist: $RPM_PATH"
    [ -n "$BOX64_BIN" ] || die "Box64 must be installed before installing this package."
    [ -e "/lib/modules/$(uname -r)/build" ] || die "Missing matching kernel headers."

    echo
    echo "RPM metadata:"
    run rpm -qpi "$RPM_PATH"
    echo
    echo "RPM dependencies:"
    run rpm -qpR "$RPM_PATH"

    run sudo "$PKG_MANAGER" install -y "$RPM_PATH"
fi

echo
echo "Package state:"
rpm -q abb-agent-arm64-box64 || true

echo
echo "Installed files:"
rpm -ql abb-agent-arm64-box64 2>/dev/null | sed -n '1,120p' || true

echo
echo "DKMS:"
dkms status synosnap 2>/dev/null || true

echo
echo "Kernel module:"
lsmod | grep synosnap || true
ls -l /dev/synosnap* 2>/dev/null || true

if [ "$START_SERVICE" -eq 1 ]; then
    run sudo systemctl start abb-box64.service
fi

echo
echo "systemd:"
systemctl is-enabled abb-box64.service || true
systemctl is-active abb-box64.service || true
systemctl status abb-box64.service --no-pager || true

echo
echo "ABB CLI:"
if command -v abb-cli >/dev/null 2>&1; then
    abb-cli -s || true
else
    echo "abb-cli wrapper not found"
fi

echo
echo "SELinux denials:"
if command -v ausearch >/dev/null 2>&1; then
    sudo ausearch -m avc,user_avc -ts recent || true
else
    echo "ausearch not available"
fi

echo
echo "Recent service journal:"
sudo journalctl -u abb-box64.service -n 120 --no-pager || true

if [ "$DO_UNINSTALL" -eq 1 ]; then
    echo
    echo "Uninstall check:"
    run sudo systemctl stop abb-box64.service
    run sudo "$PKG_MANAGER" remove -y abb-agent-arm64-box64
    rpm -q abb-agent-arm64-box64 || true
    dkms status synosnap 2>/dev/null || true
    systemctl status abb-box64.service --no-pager || true
fi
