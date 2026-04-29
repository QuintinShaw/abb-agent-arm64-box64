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

## SELinux Check

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

Keep SELinux enforcing results separate from permissive-mode results.
