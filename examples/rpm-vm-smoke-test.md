# RPM VM Smoke Test Example

[English](rpm-vm-smoke-test.md) | [中文](rpm-vm-smoke-test.zh-CN.md)

Run this only in a disposable ARM64 RPM-based VM or spare test host.

## Prepare

```bash
sudo dnf install -y git dkms gcc make kernel-devel unzip wget rpm-build cpio tar systemd
git clone https://github.com/QuintinShaw/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
```

Install Box64 through your preferred pinned method. The helper script is
Debian-oriented; on RPM systems, prefer an audited local package or a pinned
manual Box64 build.

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
sudo abb-cli -s
```

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
