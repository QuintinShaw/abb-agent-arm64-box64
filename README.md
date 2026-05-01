# abb-agent-arm64-box64

Run Synology Active Backup for Business Linux x86_64 Agent on ARM64 using native synosnap DKMS + Box64.

Status: Beta testing. Core ARM64 VM backup/restore validation has passed.

Languages: English | [中文](README.zh-CN.md)

This repository does not contain or redistribute Synology binaries.

| Area | Status |
| --- | --- |
| DEB packaging | Beta, validated on ARM64 Debian/Ubuntu-style systems |
| RPM packaging | Beta, validated on Rocky Linux 9.7 ARM64 VM |
| Backup/restore | Whole-device and file-restore validation completed in ARM64 VMs |
| Releases | Source-only; no Synology binaries or generated packages |

## Beta Notice

This project is unofficial and unsupported by Synology. It has entered beta
testing after completing core ARM64 VM backup/restore validation. You can try
installing it on compatible ARM64 Linux systems; if you hit issues, please open
a GitHub issue with redacted logs, distro/kernel details, package type, and
reproduction steps.

Backup software must still be validated in your own environment before you rely
on it for important data. Keep an independent recovery path and run your own
restore tests. See [docs/production-test-plan.md](docs/production-test-plan.md).

## Quickstart

For the lowest-friction trial on a compatible ARM64 Linux system:

```bash
curl -L -o abb-agent-arm64-box64-source.tar.gz \
  https://github.com/QuintinShaw/abb-agent-arm64-box64/releases/latest/download/abb-agent-arm64-box64-source.tar.gz
tar -xzf abb-agent-arm64-box64-source.tar.gz
cd abb-agent-arm64-box64-*
./scripts/quickstart.sh --yes
sudo abb-cli -c
```

The quickstart script installs prerequisites, builds a local package from
Synology's official package input, installs it, enables `abb-box64.service`, and
runs a read-only preflight check. It does not redistribute Synology binaries.

See [docs/quickstart.md](docs/quickstart.md), [docs/preflight.md](docs/preflight.md),
and [docs/compatibility-matrix.md](docs/compatibility-matrix.md).

## What This Repository Does Not Contain

This repository does not distribute Synology proprietary binaries.

Do not upload:

- Official Synology zip, deb, or rpm files
- Generated deb/rpm packages containing Synology binaries
- NAS credentials, certificates, tokens, or unredacted logs

The build script downloads the official Synology package on your ARM64 machine,
or uses a local official zip that you provide with `ABB_OFFICIAL_ZIP` or
`ABB_OFFICIAL_RPM_ZIP`.

## Validation Summary

Core ARM64 VM validation has been completed across Debian/Ubuntu-style DEB
packaging, RPM packaging, native ARM64 `synosnap` DKMS, Box64-based ABB
userspace, whole-device backup, file restore, and checksum verification.

Detailed results are documented in [docs/test-report.md](docs/test-report.md).

## Install Deb On Debian/Ubuntu

Manual DEB path:

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
curl -L -o abb-agent-arm64-box64-source.tar.gz \
  https://github.com/QuintinShaw/abb-agent-arm64-box64/releases/latest/download/abb-agent-arm64-box64-source.tar.gz
tar -xzf abb-agent-arm64-box64-source.tar.gz
cd abb-agent-arm64-box64-*
sudo ./scripts/install-box64.sh
./scripts/build-deb.sh
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
sudo systemctl enable --now abb-box64.service
sudo abb-cli -c
```

The service is not enabled automatically. Enable and start it manually when testing:

```bash
sudo systemctl enable --now abb-box64.service
```

`install-box64.sh` is a convenience helper. It defaults to `BOX64_REF=v0.4.2`, builds as `SUDO_USER` when available, and uses root only for dependency installation and final install. You can also install Box64 yourself.

## Build

Default build downloads the official Synology zip:

```bash
./scripts/build-deb.sh
```

To use a manually downloaded official zip:

```bash
ABB_OFFICIAL_ZIP=/path/to/official.zip ABB_OFFICIAL_SHA256=<sha256> ./scripts/build-deb.sh
```

Do not run `build-deb.sh` with `sudo`. The build stage downloads and extracts external packages and intentionally runs as an unprivileged user. The generated deb can then be installed with `sudo dpkg -i`.

Expected output:

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

This generated package is for your own local machine. Do not publish it to GitHub Releases because it contains Synology proprietary files extracted from the official package.

## Build RPM On RPM-Based Systems

RPM support is beta-stage and should be tested in a disposable ARM64 RPM VM or spare host:

Before installing the generated RPM, install a distro-compatible Box64, DKMS
from EPEL or another trusted source, matching `kernel-devel-$(uname -r)`, and
the x86_64 runtime libraries needed by Box64. See [docs/rpm.md](docs/rpm.md)
for the Rocky/RHEL notes.

```bash
./scripts/build-rpm.sh
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl enable --now abb-box64.service
sudo abb-cli -s
```

The RPM builder uses Synology's official x86_64 rpm zip and verifies the default download with a pinned SHA256. For manual input:

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/official-rpm.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh
```

See [docs/rpm.md](docs/rpm.md). RPM compatibility requires separate validation for `kernel-devel`, DKMS, systemd, SELinux, and the official rpm package layout.
Synology's official RPM archive places `abb-cli` at `/bin/abb-cli`; this
builder relocates that official binary into the local ABB payload so the
`/usr/local/bin/abb-cli` wrapper works through Box64. Do not redistribute that
binary or any generated package containing it.

## Feedback

Use GitHub issues for reproducible install, backup, restore, and distro
validation reports. Use GitHub Discussions for setup questions and successful
validation notes. Redact logs before sharing them.

Helpful links:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [ROADMAP.md](ROADMAP.md)
- [docs/compatibility-matrix.md](docs/compatibility-matrix.md)
- [docs/test-report.md](docs/test-report.md)
- [SECURITY.md](SECURITY.md)

## Release Policy

Source-only releases are allowed. The release download is a source archive made
from tracked repository files. Do not attach generated `.deb` / `.rpm` files,
official Synology zip/deb/rpm files, extracted Synology files, NAS logs, or
credentials to GitHub Releases.

## Verify

```bash
lsmod | grep synosnap
systemctl status abb-box64.service --no-pager
abb-cli -s
```

Then check the NAS UI and confirm the agent is online.

## Restore Validation

Minimal safe validation flow:

1. Create a temporary test block device or test directory.
2. Generate test files and save `sha256sum` output.
3. Create a NAS task that selects only the test scope.
4. Run a first backup.
5. Modify test data and run an incremental backup.
6. Restore to a separate temporary path.
7. Compare restored file hashes against the source hashes.

See [docs/restore-validation.md](docs/restore-validation.md) and [examples/abb-test-loop-device.md](examples/abb-test-loop-device.md).

Production-oriented validation should also cover interrupted backups, forced reboots, kernel upgrades, package removal, and SELinux/AppArmor behavior. See [examples/production-test-checklist.md](examples/production-test-checklist.md).

## Compatibility Shim

During validation, x86_64 libmount under Box64 returned an empty mount table even though it opened and read `/proc/self/mountinfo`. This made the NAS custom-volume list empty. This repository includes a small x86_64 preload shim for the libmount functions ABB uses for mount enumeration. It is built locally with `x86_64-linux-gnu-gcc` during packaging and installed under:

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

The wrapper loads it through `BOX64_LD_PRELOAD` when present. This is a beta-stage compatibility workaround.

## Legal Notes

Synology and Active Backup for Business are trademarks or registered trademarks of Synology Inc.

This project is not affiliated with Synology Inc. and is not officially supported by Synology.

This project does not distribute Synology proprietary binaries. Users must obtain official Synology packages from Synology. Scripts in this repository are provided for educational and interoperability research purposes only.

If you believe this project infringes your rights, contact `github@xyt.email`.

## References

- https://github.com/ardnew/synology-active-backup-business-agent
- https://github.com/Peppershade/abb-linux-agent-6.12
- https://github.com/ptitSeb/box64
- Synology official Active Backup for Business Agent download page
