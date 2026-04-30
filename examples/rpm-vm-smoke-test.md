# RPM VM Smoke Test Example

[English](rpm-vm-smoke-test.md) | [中文](rpm-vm-smoke-test.zh-CN.md)

Run this only in a disposable ARM64 RPM-based VM or spare test host.

## Prepare

```bash
sudo dnf install -y epel-release
echo HARDLINK=no | sudo tee /etc/sysconfig/kernel
sudo dnf install -y --setopt=install_weak_deps=False \
  git dkms gcc make "kernel-devel-$(uname -r)" elfutils-libelf-devel \
  unzip wget rpm-build cpio tar systemd cmake
git clone https://github.com/QuintinShaw/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
```

Install Box64 through your preferred pinned method. The helper script is
Debian-oriented. On RPM systems, prefer a trusted distro package when one is
available. Fedora packages Box64:

```bash
sudo dnf install -y box64
```

The Box64 binary must be compatible with the VM's distro glibc. Do not copy a
binary from Ubuntu to Rocky/RHEL unless you have verified that it does not
require a newer glibc than the VM provides. Fedora RPMs may also require a newer
glibc than Rocky/RHEL 9 provides.

If no trusted compatible Box64 package exists for the target RPM distro, avoid
building it in a slow no-KVM VM. Use a physical ARM64 host, an ARM64 VM with
KVM, or an EL9-compatible ARM64 build environment, then copy only the resulting
Box64 binary into the disposable VM for package validation.

Make sure Box64 can also find x86_64 `libstdc++.so.6` and `libgcc_s.so.1`.
On Rocky/RHEL 9, obtain them from a trusted Box64 package or from the matching
Rocky/RHEL x86_64 runtime RPMs and place them in a Box64 search path such as
`/usr/lib/box64-x86_64-linux-gnu`.

## Build

```bash
./scripts/build-rpm.sh
```

The generated rpm is local-only:

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

## Install

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

The official RPM payload may not include every helper binary present in the deb
payload. If `/opt/Synology/ActiveBackupforBusiness/bin/abb-cli` is absent, use
systemd and journal checks for the smoke test instead of `abb-cli -s`.

Or run the packaged verifier:

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --start-service
```

The first command is read-only. The install command verifies rpm metadata,
installs the package through `dnf` or `yum`, checks DKMS state, checks the
kernel module, prints systemd state, and collects recent journal and SELinux
denials. It does not register the host to NAS and does not start backups.

A successful service smoke test should show `ABB backup service starts`, then a
kernel-driver check in the service journal. The package creates `/opt/synosnap`
for ABB's snapshot history database; if that directory is missing, the service
can exit after logging `SnapshotHistoryDB: Failed to open database`.

## SELinux Check

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

Keep SELinux enforcing results separate from permissive-mode results.

## Uninstall Check

After service and DKMS checks, validate package removal in the disposable VM:

```bash
./scripts/verify-rpm-vm.sh --uninstall
```

Do not use uninstall output as proof that NAS-side tasks or backup data were
removed. Those are outside the local RPM package scope.
