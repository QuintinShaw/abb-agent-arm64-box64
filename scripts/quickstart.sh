#!/usr/bin/env bash
set -Eeuo pipefail

YES=0
CONNECT=0
SKIP_BOX64=0
PACKAGE_MODE="auto"
OFFICIAL_ZIP="${ABB_OFFICIAL_ZIP:-}"
OFFICIAL_SHA256="${ABB_OFFICIAL_SHA256:-}"
OFFICIAL_RPM_ZIP="${ABB_OFFICIAL_RPM_ZIP:-}"
OFFICIAL_RPM_SHA256="${ABB_OFFICIAL_RPM_SHA256:-}"
BOX64_REF="${BOX64_REF:-v0.4.2}"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/quickstart.sh --yes
  ./scripts/quickstart.sh --yes --connect
  ./scripts/quickstart.sh --yes --package deb
  ./scripts/quickstart.sh --yes --package rpm

Options:
  --yes               Run without confirmation prompts.
  --connect           Run "sudo abb-cli -c" after installation.
  --skip-box64        Do not install Box64; require an existing compatible box64.
  --package MODE      auto, deb, or rpm. Default: auto.
  --official-zip PATH Use a local official Synology DEB zip.
  --official-sha256 HASH
  --official-rpm-zip PATH
  --official-rpm-sha256 HASH
  -h, --help

This script does not bundle or redistribute Synology binaries. It builds a
local package from Synology's official download or from the official archive
path you provide, then installs the generated local package on this machine.
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo
    echo "== $* =="
}

confirm() {
    [ "$YES" -eq 1 ] && return 0
    cat <<'EOF'
This quickstart will install build dependencies, build a local package from
official Synology input, install that generated package, and enable
abb-box64.service.

Do not continue on a machine where you are not ready to run ABB Agent tests.
EOF
    printf 'Continue? [y/N] '
    read -r answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) die "Cancelled." ;;
    esac
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

box64_exists() {
    command -v box64 >/dev/null 2>&1 || [ -x /usr/local/bin/box64 ] || [ -x /usr/bin/box64 ]
}

load_os_release() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    else
        ID="unknown"
        ID_LIKE=""
    fi
}

detect_mode() {
    if [ "$PACKAGE_MODE" != "auto" ]; then
        return
    fi
    if command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1; then
        PACKAGE_MODE="deb"
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        PACKAGE_MODE="rpm"
    else
        die "Could not detect DEB or RPM package manager. Use --package deb or --package rpm after installing package tools."
    fi
}

install_box64_deb() {
    if [ "$SKIP_BOX64" -eq 1 ]; then
        box64_exists || die "--skip-box64 was set, but no box64 binary was found."
        return
    fi
    if box64_exists; then
        echo "Box64 already exists; leaving it unchanged."
        return
    fi
    info "Installing Box64 from pinned source"
    sudo BOX64_REF="$BOX64_REF" ./scripts/install-box64.sh
}

install_box64_rpm() {
    if [ "$SKIP_BOX64" -eq 1 ]; then
        box64_exists || die "--skip-box64 was set, but no box64 binary was found."
        return
    fi
    if box64_exists; then
        echo "Box64 already exists; leaving it unchanged."
        return
    fi
    if [ "${ID:-}" = "fedora" ]; then
        info "Installing Fedora Box64 package"
        sudo dnf install -y box64
        return
    fi
    die "No Box64 binary found. Install a Box64 build compatible with this RPM distro, then rerun with --skip-box64 if needed. Do not copy Box64 from another distro unless glibc compatibility is verified."
}

build_deb() {
    info "Installing DEB build dependencies"
    sudo apt-get update
    sudo apt-get install -y dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu

    install_box64_deb

    info "Building local DEB"
    if [ -n "$OFFICIAL_ZIP" ]; then
        [ -n "$OFFICIAL_SHA256" ] || die "--official-zip requires --official-sha256"
        ABB_OFFICIAL_ZIP="$OFFICIAL_ZIP" ABB_OFFICIAL_SHA256="$OFFICIAL_SHA256" ./scripts/build-deb.sh
    else
        ./scripts/build-deb.sh
    fi

    deb_path=(dist/abb-agent-arm64-box64_*_arm64.deb)
    [ -f "${deb_path[0]}" ] || die "Generated DEB not found in dist/."

    info "Installing local DEB"
    sudo dpkg -i "${deb_path[0]}"
    sudo apt-get -f install -y
}

build_rpm() {
    local pkg_manager
    if command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        pkg_manager="yum"
    else
        die "dnf or yum is required for RPM quickstart."
    fi

    if [ "${ID:-}" = "rocky" ] || [ "${ID:-}" = "almalinux" ] || [ "${ID:-}" = "rhel" ] || [[ " ${ID_LIKE:-} " == *" rhel "* ]]; then
        info "Installing EPEL for DKMS availability"
        sudo "$pkg_manager" install -y epel-release
    fi

    info "Installing RPM build dependencies"
    sudo "$pkg_manager" install -y --setopt=install_weak_deps=False \
        git dkms gcc make "kernel-devel-$(uname -r)" elfutils-libelf-devel \
        kmod systemd unzip wget rpm-build rpmdevtools cpio tar

    if ! command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
        info "Installing x86_64 cross compiler for the mount shim"
        sudo "$pkg_manager" install -y gcc-x86_64-linux-gnu || die "x86_64-linux-gnu-gcc is required to build the mount shim. Install a distro cross compiler or use the container RPM assembly path in docs/rpm.md."
    fi

    install_box64_rpm

    info "Building local RPM"
    if [ -n "$OFFICIAL_RPM_ZIP" ]; then
        [ -n "$OFFICIAL_RPM_SHA256" ] || die "--official-rpm-zip requires --official-rpm-sha256"
        ABB_OFFICIAL_RPM_ZIP="$OFFICIAL_RPM_ZIP" ABB_OFFICIAL_RPM_SHA256="$OFFICIAL_RPM_SHA256" ./scripts/build-rpm.sh
    else
        ./scripts/build-rpm.sh
    fi

    rpm_path=(dist/abb-agent-arm64-box64-*.aarch64.rpm)
    [ -f "${rpm_path[0]}" ] || die "Generated RPM not found in dist/."

    info "Installing local RPM"
    sudo "$pkg_manager" install -y "${rpm_path[0]}"
}

enable_service() {
    info "Enabling ABB service"
    sudo systemctl enable --now abb-box64.service
}

run_post_checks() {
    info "Running read-only preflight summary"
    ./scripts/preflight-check.sh || true

    if [ "$CONNECT" -eq 1 ]; then
        info "Starting NAS registration"
        sudo abb-cli -c
    else
        cat <<'EOF'

Next step:
  sudo abb-cli -c

Then create a scoped test task in the NAS UI and validate restore before using
the agent for important data.
EOF
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes)
            YES=1
            shift
            ;;
        --connect)
            CONNECT=1
            shift
            ;;
        --skip-box64)
            SKIP_BOX64=1
            shift
            ;;
        --package)
            [ "$#" -ge 2 ] || die "--package requires auto, deb, or rpm"
            PACKAGE_MODE="$2"
            case "$PACKAGE_MODE" in auto|deb|rpm) ;; *) die "Invalid --package value: $PACKAGE_MODE" ;; esac
            shift 2
            ;;
        --official-zip)
            [ "$#" -ge 2 ] || die "--official-zip requires a path"
            OFFICIAL_ZIP="$2"
            shift 2
            ;;
        --official-sha256)
            [ "$#" -ge 2 ] || die "--official-sha256 requires a hash"
            OFFICIAL_SHA256="$2"
            shift 2
            ;;
        --official-rpm-zip)
            [ "$#" -ge 2 ] || die "--official-rpm-zip requires a path"
            OFFICIAL_RPM_ZIP="$2"
            shift 2
            ;;
        --official-rpm-sha256)
            [ "$#" -ge 2 ] || die "--official-rpm-sha256 requires a hash"
            OFFICIAL_RPM_SHA256="$2"
            shift 2
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

[ "$(id -u)" -ne 0 ] || die "Run quickstart as a regular user with sudo access, not as root."
case "$(uname -m)" in
    aarch64|arm64) ;;
    *) die "This quickstart targets ARM64/aarch64 systems. Current arch: $(uname -m)" ;;
esac

need_cmd sudo
sudo -v
load_os_release
detect_mode
confirm

case "$PACKAGE_MODE" in
    deb) build_deb ;;
    rpm) build_rpm ;;
    *) die "Unexpected package mode: $PACKAGE_MODE" ;;
esac

enable_service
run_post_checks
