#!/usr/bin/env bash
set -Eeuo pipefail

section() {
    printf '\n== %s ==\n' "$1"
}

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'OK: %s -> %s\n' "$1" "$(command -v "$1")"
        return 0
    fi
    printf 'WARN: missing command: %s\n' "$1"
    return 1
}

print_os_release() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        printf 'os=%s\n' "${PRETTY_NAME:-unknown}"
    else
        printf 'os=unknown\n'
    fi
}

find_box64() {
    if command -v box64 >/dev/null 2>&1; then
        command -v box64
        return 0
    fi
    for candidate in /usr/local/bin/box64 /usr/bin/box64; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

section "System"
print_os_release
printf 'arch=%s\n' "$(uname -m)"
printf 'kernel=%s\n' "$(uname -r)"

case "$(uname -m)" in
    aarch64|arm64) printf 'OK: ARM64 architecture\n' ;;
    *) printf 'WARN: this project targets ARM64/aarch64 systems\n' ;;
esac

section "Required Commands"
for cmd in dkms gcc make modprobe systemctl; do
    check_cmd "$cmd" || true
done

if command -v dpkg >/dev/null 2>&1; then
    printf 'OK: dpkg package tools available\n'
elif command -v rpm >/dev/null 2>&1; then
    printf 'OK: rpm package tools available\n'
else
    printf 'WARN: neither dpkg nor rpm was found\n'
fi

section "Kernel Headers"
if [ -e "/lib/modules/$(uname -r)/build" ]; then
    printf 'OK: /lib/modules/%s/build exists\n' "$(uname -r)"
else
    printf 'WARN: missing /lib/modules/%s/build\n' "$(uname -r)"
    printf '      Debian/Ubuntu: install linux-headers-$(uname -r)\n'
    printf '      RPM systems: install kernel-devel-$(uname -r)\n'
fi

section "Box64"
if BOX64_BIN="$(find_box64)"; then
    printf 'OK: box64=%s\n' "$BOX64_BIN"
    "$BOX64_BIN" --version || true
else
    printf 'WARN: box64 not found\n'
fi

section "x86_64 Runtime Libraries"
for lib in libstdc++.so.6 libgcc_s.so.1 libm.so.6 libc.so.6; do
    found=""
    for dir in \
        /opt/Synology/ActiveBackupforBusiness/lib \
        /opt/Synology/ActiveBackupforBusiness/amd64-libs/lib/x86_64-linux-gnu \
        /opt/Synology/ActiveBackupforBusiness/amd64-libs/usr/lib/x86_64-linux-gnu \
        /usr/lib/box64-x86_64-linux-gnu \
        /usr/lib/x86_64-linux-gnu \
        /lib/x86_64-linux-gnu
    do
        if [ -e "$dir/$lib" ]; then
            found="$dir/$lib"
            break
        fi
    done
    if [ -n "$found" ]; then
        printf 'OK: %s -> %s\n' "$lib" "$found"
    else
        printf 'WARN: %s not found in common Box64 library paths\n' "$lib"
    fi
done

section "Package State"
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W abb-agent-arm64-box64 2>/dev/null || true
fi
if command -v rpm >/dev/null 2>&1; then
    rpm -q abb-agent-arm64-box64 2>/dev/null || true
fi

section "synosnap"
dkms status synosnap 2>/dev/null || printf 'WARN: no DKMS status for synosnap\n'
lsmod | grep synosnap || true
ls -l /dev/synosnap* 2>/dev/null || true

section "systemd"
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-enabled abb-box64.service 2>/dev/null || true
    systemctl is-active abb-box64.service 2>/dev/null || true
    systemctl status abb-box64.service --no-pager 2>/dev/null | sed -n '1,40p' || true
else
    printf 'WARN: systemctl not found\n'
fi

section "MAC Policy"
if command -v getenforce >/dev/null 2>&1; then
    printf 'SELinux=%s\n' "$(getenforce)"
else
    printf 'SELinux=unknown\n'
fi
if command -v aa-status >/dev/null 2>&1; then
    aa-status 2>/dev/null | sed -n '1,20p' || true
else
    printf 'AppArmor=unknown\n'
fi

section "ABB CLI"
if command -v abb-cli >/dev/null 2>&1; then
    abb-cli -s || true
elif command -v service-ctrl >/dev/null 2>&1; then
    printf 'abb-cli not found; service-ctrl wrapper exists\n'
    service-ctrl -s || true
else
    printf 'WARN: abb-cli and service-ctrl wrappers not found\n'
fi

section "Reminder"
printf 'Redact NAS hostnames, account names, tokens, certificates, UUIDs, and internal domains before sharing output.\n'
