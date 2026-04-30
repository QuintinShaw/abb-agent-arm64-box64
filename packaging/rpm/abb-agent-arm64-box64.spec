Name:           abb-agent-arm64-box64
Version:        @VERSION@
Release:        @RELEASE@%{?dist}
Summary:        Community ARM64 wrapper/package builder for Synology Active Backup for Business Agent via Box64
License:        MIT AND LicenseRef-Synology-Proprietary
URL:            https://github.com/QuintinShaw/abb-agent-arm64-box64
BuildArch:      aarch64
Source0:        %{name}-%{version}-@RELEASE@-payload.tar.gz
AutoReqProv:    no

%global __strip /bin/true
%global __brp_strip /bin/true
%global __brp_strip_comment_note /bin/true
%global __brp_strip_static_archive /bin/true

Requires:       dkms
Requires:       gcc
Requires:       make
Requires:       kmod
Requires:       systemd
Requires:       glibc

%description
Runs Synology ABB x86_64 Linux agent on ARM64 using Box64 and a native ARM64
synosnap DKMS module. This package is unofficial and unsupported by Synology.
It is generated locally and contains files extracted from official Synology
packages supplied by the user or downloaded from Synology.

%prep
%setup -q -c -T
tar -xzf %{SOURCE0}

%build

%install
mkdir -p %{buildroot}
cp -a . %{buildroot}/

%post
set -e

BOX64_BIN=""
if [ -x /usr/local/bin/box64 ]; then
    BOX64_BIN=/usr/local/bin/box64
elif [ -x /usr/bin/box64 ]; then
    BOX64_BIN=/usr/bin/box64
fi

if [ -z "$BOX64_BIN" ]; then
    echo "ERROR: box64 was not found at /usr/local/bin/box64 or /usr/bin/box64." >&2
    echo "Install Box64 first, then reinstall or run:" >&2
    echo "  sudo rpm -Uvh --replacepkgs %{name}-%{version}-%{release}.aarch64.rpm" >&2
    exit 1
fi

for cmd in dkms gcc make modprobe; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: missing required command: $cmd" >&2
        exit 1
    fi
done

if [ ! -e "/lib/modules/$(uname -r)/build" ]; then
    echo "ERROR: kernel headers for $(uname -r) are missing." >&2
    echo "Install the matching kernel-devel package, then reinstall this package." >&2
    exit 1
fi

install -d -m 0755 /opt/synosnap

if [ -d /usr/src/synosnap-@SYNOSNAP_VERSION@ ]; then
    dkms add -m synosnap -v @SYNOSNAP_VERSION@ 2>/dev/null || true
    dkms build -m synosnap -v @SYNOSNAP_VERSION@
    dkms install -m synosnap -v @SYNOSNAP_VERSION@
    modprobe synosnap || true
else
    echo "WARNING: /usr/src/synosnap-@SYNOSNAP_VERSION@ not found; DKMS module was not installed." >&2
fi

systemctl daemon-reload || true

echo "abb-agent-arm64-box64 installed."
echo "Service was not enabled automatically."
echo "Enable and start it with: sudo systemctl enable --now abb-box64.service"
echo "Register with: sudo abb-cli -c"

%preun
if [ "$1" = "0" ]; then
    systemctl stop abb-box64.service >/dev/null 2>&1 || true
    pkill -TERM -f synology-backupd >/dev/null 2>&1 || true
    sleep 2 || true
    pkill -KILL -f synology-backupd >/dev/null 2>&1 || true
    modprobe -r synosnap >/dev/null 2>&1 || rmmod synosnap >/dev/null 2>&1 || true
    dkms remove -m synosnap -v @SYNOSNAP_VERSION@ --all >/dev/null 2>&1 || true
fi

%postun
systemctl daemon-reload >/dev/null 2>&1 || true

%files
/usr/share/doc/%{name}
/opt/Synology/ActiveBackupforBusiness
/opt/synosnap
/usr/src/synosnap-@SYNOSNAP_VERSION@
%dir /usr/lib/synosnap
/usr/lib/synosnap/libsynosnap.so
/usr/local/bin/abb-box64-wrapper
/usr/local/bin/abb-cli
/usr/local/bin/service-ctrl
/usr/local/bin/sbdctl
/usr/local/lib/abb-agent-arm64-box64
/etc/systemd/system/abb-box64.service

%changelog
* Wed Apr 29 2026 Community <github@xyt.email> - @VERSION@-@RELEASE@
- Initial experimental RPM packaging support.
