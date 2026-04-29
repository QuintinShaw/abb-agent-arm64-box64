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

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo abb-cli -s
```

The service is not enabled automatically.

The repository also includes a VM-side verifier:

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --start-service
./scripts/verify-rpm-vm.sh --uninstall
```

Default mode is read-only. Install and uninstall modes are explicit because
they change system packages, DKMS state, and systemd state. The verifier does
not register to NAS, create tasks, or run backup/restore tests.

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
