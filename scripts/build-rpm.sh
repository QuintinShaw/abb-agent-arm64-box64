#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="abb-agent-arm64-box64"
VERSION="3.2.0"
RELEASE="5053"
FULL_VERSION="${VERSION}-${RELEASE}"
SYNOSNAP_VERSION="0.12.10"
RPM_NAME="${PROJECT_NAME}-${VERSION}-${RELEASE}.aarch64.rpm"
OFFICIAL_URL="https://global.synologydownload.com/download/Utility/ActiveBackupBusinessAgent/3.2.0-5053/Linux/x86_64/Synology%20Active%20Backup%20for%20Business%20Agent-3.2.0-5053-x64-rpm.zip"
OFFICIAL_SHA256="ad5c5b0117b4960aa29bd39d1570f9bcc61971a22c1b4c2ae41ddb1874c77d2b"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$ROOT_DIR/cache"
BUILD_DIR="$ROOT_DIR/build/rpm"
DIST_DIR="$ROOT_DIR/dist"
RPMBUILD_DIR="$BUILD_DIR/rpmbuild"
ZIP_CACHE="$CACHE_DIR/official-abb-agent-${FULL_VERSION}-x64-rpm.zip"
ZIP_EXTRACT_DIR="$BUILD_DIR/official-zip"
AGENT_ROOT="$BUILD_DIR/agent-root"
SYNOSNAP_ROOT="$BUILD_DIR/synosnap-root"
PKG_ROOT="$BUILD_DIR/pkgroot"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64) ;;
    *) die "This RPM builder must run on ARM64/aarch64. Current architecture: $ARCH" ;;
esac

if [ "$(id -u)" -eq 0 ] && [ "${ALLOW_ROOT_BUILD:-0}" != "1" ]; then
    die "Do not run build-rpm.sh as root. Run: ./scripts/build-rpm.sh

The build stage downloads and extracts external packages and should run as an
unprivileged user. Use ALLOW_ROOT_BUILD=1 only for disposable CI or containers."
fi

for cmd in unzip find grep install cp rm mkdir sha256sum rpm2cpio cpio rpmbuild tar sed; do
    need_cmd "$cmd"
done

if ! command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
    die "x86_64-linux-gnu-gcc is required to build mount_shim.so."
fi

mkdir -p "$CACHE_DIR" "$BUILD_DIR" "$DIST_DIR"
rm -rf "$ZIP_EXTRACT_DIR" "$AGENT_ROOT" "$SYNOSNAP_ROOT" "$PKG_ROOT" "$RPMBUILD_DIR"
mkdir -p "$ZIP_EXTRACT_DIR" "$AGENT_ROOT" "$SYNOSNAP_ROOT" "$PKG_ROOT"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/BUILDROOT" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

if [ -n "${ABB_OFFICIAL_RPM_ZIP:-}" ]; then
    [ -f "$ABB_OFFICIAL_RPM_ZIP" ] || die "ABB_OFFICIAL_RPM_ZIP does not exist: $ABB_OFFICIAL_RPM_ZIP"
    OFFICIAL_ZIP="$ABB_OFFICIAL_RPM_ZIP"
    EXPECTED_SHA256="${ABB_OFFICIAL_RPM_SHA256:-}"
    if [ -z "$EXPECTED_SHA256" ] && [ "${ABB_ALLOW_UNVERIFIED_ZIP:-0}" != "1" ]; then
        die "ABB_OFFICIAL_RPM_SHA256 is required when ABB_OFFICIAL_RPM_ZIP is used.

Example:
  ABB_OFFICIAL_RPM_ZIP=/path/to/file.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh

Set ABB_ALLOW_UNVERIFIED_ZIP=1 only for disposable local experiments."
    fi
else
    OFFICIAL_ZIP="$ZIP_CACHE"
    EXPECTED_SHA256="$OFFICIAL_SHA256"
    if [ ! -f "$OFFICIAL_ZIP" ]; then
        if command -v wget >/dev/null 2>&1; then
            wget -O "$OFFICIAL_ZIP" "$OFFICIAL_URL"
        elif command -v curl >/dev/null 2>&1; then
            curl -L -o "$OFFICIAL_ZIP" "$OFFICIAL_URL"
        else
            die "Need wget or curl to download the official Synology rpm zip."
        fi
    fi
fi

if [ -n "${EXPECTED_SHA256:-}" ]; then
    printf '%s  %s\n' "$EXPECTED_SHA256" "$OFFICIAL_ZIP" | sha256sum -c -
elif [ "${ABB_ALLOW_UNVERIFIED_ZIP:-0}" = "1" ]; then
    echo "WARNING: skipping official zip SHA256 verification by request." >&2
else
    die "No SHA256 verification configured."
fi

unzip -q "$OFFICIAL_ZIP" -d "$ZIP_EXTRACT_DIR"

if [ -f "$ZIP_EXTRACT_DIR/install.run" ]; then
    RUN_EXTRACT_DIR="$ZIP_EXTRACT_DIR/install.run.extract"
    mkdir -p "$RUN_EXTRACT_DIR"
    echo "Extracting makeself payload without running installer payload."
    echo "This executes the makeself shell extractor as the current unprivileged user."
    sh "$ZIP_EXTRACT_DIR/install.run" --noexec --target "$RUN_EXTRACT_DIR"
fi

AGENT_RPM="$(find "$ZIP_EXTRACT_DIR" -type f -name '*.rpm' | grep -Ei 'Active.*Backup.*Business.*Agent|ActiveBackup' | head -n 1 || true)"
SYNOSNAP_RPM="$(find "$ZIP_EXTRACT_DIR" -type f -name '*.rpm' | grep -Ei 'synosnap' | head -n 1 || true)"

[ -n "$AGENT_RPM" ] || die "Could not find the official ABB agent .rpm inside the zip."
[ -n "$SYNOSNAP_RPM" ] || die "Could not find the official synosnap .rpm inside the zip."

(cd "$AGENT_ROOT" && rpm2cpio "$AGENT_RPM" | cpio -idm --quiet)
(cd "$SYNOSNAP_ROOT" && rpm2cpio "$SYNOSNAP_RPM" | cpio -idm --quiet)

if [ -d "$AGENT_ROOT/opt/Synology/ActiveBackupforBusiness" ]; then
    mkdir -p "$PKG_ROOT/opt/Synology"
    cp -a "$AGENT_ROOT/opt/Synology/ActiveBackupforBusiness" "$PKG_ROOT/opt/Synology/"
else
    die "Official agent package did not contain /opt/Synology/ActiveBackupforBusiness"
fi

SYNOSNAP_SRC="$(find "$SYNOSNAP_ROOT/usr/src" "$AGENT_ROOT/usr/src" -maxdepth 2 -type d -name 'synosnap-*' 2>/dev/null | head -n 1 || true)"
[ -n "$SYNOSNAP_SRC" ] || die "Could not locate synosnap DKMS source in official rpm packages."
mkdir -p "$PKG_ROOT/usr/src"
cp -a "$SYNOSNAP_SRC" "$PKG_ROOT/usr/src/synosnap-${SYNOSNAP_VERSION}"

LIBSYNOSNAP="$(find "$AGENT_ROOT" "$SYNOSNAP_ROOT" -type f -name 'libsynosnap.so' | head -n 1 || true)"
[ -n "$LIBSYNOSNAP" ] || die "Could not locate x86_64 libsynosnap.so in official rpm packages."
mkdir -p "$PKG_ROOT/usr/lib/synosnap"
cp -a "$LIBSYNOSNAP" "$PKG_ROOT/usr/lib/synosnap/libsynosnap.so"

cp -a "$ROOT_DIR/packaging/etc" "$PKG_ROOT/"
mkdir -p "$PKG_ROOT/usr/local/bin" "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64"
cp -a "$ROOT_DIR/packaging/usr/local/bin/." "$PKG_ROOT/usr/local/bin/"
cp -a "$ROOT_DIR/packaging/usr/local/lib/abb-agent-arm64-box64/mount_shim.c" "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/"
cp -a "$ROOT_DIR/packaging/usr/local/lib/abb-agent-arm64-box64/mount_shim.map" "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/"

x86_64-linux-gnu-gcc -shared -fPIC \
    -Wl,--version-script="$ROOT_DIR/packaging/usr/local/lib/abb-agent-arm64-box64/mount_shim.map" \
    -o "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/mount_shim.so" \
    "$ROOT_DIR/packaging/usr/local/lib/abb-agent-arm64-box64/mount_shim.c"

mkdir -p "$PKG_ROOT/usr/share/doc/$PROJECT_NAME"
cp -a "$ROOT_DIR/README.md" "$ROOT_DIR/README.zh-CN.md" "$ROOT_DIR/LICENSE" "$ROOT_DIR/NOTICE" "$ROOT_DIR/SECURITY.md" "$PKG_ROOT/usr/share/doc/$PROJECT_NAME/"

chmod 0755 "$PKG_ROOT/usr/local/bin/"*
chmod 0644 "$PKG_ROOT/etc/systemd/system/abb-box64.service"
chmod 0644 "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/mount_shim.c" "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/mount_shim.map"
chmod 0755 "$PKG_ROOT/usr/local/lib/abb-agent-arm64-box64/mount_shim.so"

tar -C "$PKG_ROOT" -czf "$RPMBUILD_DIR/SOURCES/${PROJECT_NAME}-${FULL_VERSION}-payload.tar.gz" .
sed \
    -e "s/@VERSION@/$VERSION/g" \
    -e "s/@RELEASE@/$RELEASE/g" \
    -e "s/@SYNOSNAP_VERSION@/$SYNOSNAP_VERSION/g" \
    "$ROOT_DIR/packaging/rpm/${PROJECT_NAME}.spec" > "$RPMBUILD_DIR/SPECS/${PROJECT_NAME}.spec"

rpmbuild \
    --define "_topdir $RPMBUILD_DIR" \
    --define "_build_id_links none" \
    --target aarch64 \
    -bb "$RPMBUILD_DIR/SPECS/${PROJECT_NAME}.spec"

RPM_OUT="$(find "$RPMBUILD_DIR/RPMS" -type f -name "${PROJECT_NAME}-${VERSION}-${RELEASE}*.aarch64.rpm" | head -n 1 || true)"
[ -n "$RPM_OUT" ] || die "rpmbuild completed but expected RPM was not found: ${PROJECT_NAME}-${VERSION}-${RELEASE}*.aarch64.rpm"
cp -a "$RPM_OUT" "$DIST_DIR/$RPM_NAME"

echo
echo "Built: $DIST_DIR/$RPM_NAME"
echo
echo "Install on a disposable RPM test VM with:"
echo "  sudo dnf install ./dist/$RPM_NAME"
echo "  sudo systemctl start abb-box64.service"
echo "  sudo abb-cli -c"
echo
echo "Do not upload dist/*.rpm to GitHub; it contains Synology proprietary files from the official package."
