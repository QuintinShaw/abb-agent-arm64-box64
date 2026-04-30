# RPM Build And Validation

[English](rpm.md) | [中文](rpm.zh-CN.md)

RPM support is experimental and must be validated in a disposable RPM-based VM
or spare ARM64 host. The script uses Synology's official x86_64 rpm zip as a
local input, extracts the official rpm payloads, and builds an aarch64 wrapper
rpm for local testing.

## Build Prerequisites

Install equivalent packages for your distribution:

```bash
sudo dnf install -y git dkms gcc make kernel-devel unzip wget rpm-build rpmdevtools cpio tar
sudo dnf install -y gcc-x86_64-linux-gnu || true
```

Some RPM distributions do not package `x86_64-linux-gnu-gcc`. In that case,
install a cross compiler from your distribution or build the compatibility shim
in a dedicated toolchain container.

## Build

Default build downloads and verifies Synology's official rpm zip:

```bash
./scripts/build-rpm.sh
```

Manual official zip:

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/official-rpm.zip \
ABB_OFFICIAL_RPM_SHA256=<sha256> \
./scripts/build-rpm.sh
```

Expected output:

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

Do not upload the generated rpm. It contains Synology proprietary files
extracted from the official package.

## Container Assembly Check

You can check package assembly without touching the host RPM database. The
provided container is Debian-based because it has the needed RPM build tools and
x86_64 cross compiler in standard packages:

```bash
podman build -f docker/Containerfile.rpm-build -t abb-rpm-build .
podman run --rm -v "$PWD:/work:Z" abb-rpm-build
```

The container copies the mounted checkout into a temporary directory, runs the
RPM builder as an unprivileged user, and copies only `dist/` back. This does
not validate DKMS, systemd, SELinux, NAS registration, backup, or restore
behavior.

## Install In A Disposable VM

RHEL-like systems usually need EPEL, or another trusted DKMS repository,
before this package can be installed. Install the headers for the running
kernel, not only the latest available kernel:

```bash
sudo dnf install -y epel-release
echo HARDLINK=no | sudo tee /etc/sysconfig/kernel
sudo dnf install -y --setopt=install_weak_deps=False \
  dkms gcc make "kernel-devel-$(uname -r)" elfutils-libelf-devel
```

Install Box64 with a method that is compatible with the target distribution.
Prefer a trusted distribution package when one exists. Fedora packages Box64,
so Fedora test VMs can use the distro package route:

```bash
sudo dnf install -y box64
```

Do not copy a Box64 binary from another distro unless you have verified its
glibc compatibility. For example, a Box64 binary built on Ubuntu 22.04 can
require `GLIBC_2.35` and fail on Rocky/RHEL 9 systems that provide glibc 2.34.
Fedora RPMs may also require a newer glibc than Rocky/RHEL 9 provides.

If no trusted compatible Box64 package exists for the target RPM distro, do not
spend time building Box64 in a slow no-KVM VM. Use a physical ARM64 host, an
ARM64 VM with KVM, or an EL9-compatible ARM64 build environment, then copy only
the locally built Box64 binary into the disposable VM for package validation.

Box64 must also be able to find x86_64 GNU runtime libraries required by the
official ABB binaries. On Rocky/RHEL 9, a service start can fail with
`Error loading needed lib libstdc++.so.6` or `libgcc_s.so.1` if those x86_64
libraries are absent. Install them through a trusted Box64/distro mechanism, or
for disposable validation only, extract the x86_64 Rocky packages into a Box64
library path such as `/usr/lib/box64-x86_64-linux-gnu`.

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

The service is not enabled automatically.
The official RPM payload may not include `/opt/Synology/ActiveBackupforBusiness/bin/abb-cli`,
so use systemd and journal checks when `abb-cli` is absent.

The package creates `/opt/synosnap` for ABB's snapshot history database. If this
directory is missing, `synology-backupd` can start and then exit with:

```text
SnapshotHistoryDB: Failed to open database at '/opt/synosnap/snapshot-history-db.sqlite'
```

The repository also includes a VM-side verifier:

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --install --start-service --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --uninstall
```

Default mode is read-only. Install and uninstall modes are explicit because
they change system packages, DKMS state, and systemd state. The verifier does
not register to NAS, create tasks, or run backup/restore tests.

Uninstall should remove the RPM, the DKMS entry, the loaded `synosnap` module,
and package-owned helper paths such as `/usr/lib/synosnap`. Runtime data under
`/opt/Synology/ActiveBackupforBusiness` and `/opt/synosnap` may remain; preserve
or remove it manually according to your test plan.

On slow emulated VMs without KVM, DKMS may take a very long time because
Synology's `synosnap` build runs many kernel API feature probes before compiling
the final module, and DKMS can trigger `dracut --regenerate-all` for every
installed kernel. This is not a good use of TCG-only QEMU. Prefer a physical
ARM64 host or an ARM64 VM with KVM for RPM install validation.

## SELinux

When SELinux is enforcing, collect denials during service start, NAS
registration, backup, and restore:

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

Do not add a broad allow policy until the denied path and operation are
understood. Keep SELinux findings in the test report.
