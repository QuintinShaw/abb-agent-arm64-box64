# abb-agent-arm64-box64

Run Synology Active Backup for Business Linux x86_64 Agent on ARM64 using native synosnap DKMS + Box64.

Status: Core ARM64 VM backup/restore validation completed; still experimental
and not production ready.

Languages: English | [中文](README.zh-CN.md)

This repository does not contain or redistribute Synology binaries.

## Risk Statement

This project is unofficial, unsupported by Synology, and intended only for learning, research, and interoperability experiments. Backup software must be validated by restore tests before it is trusted. You are responsible for your data, NAS, server, kernel, and recovery plan.

Do not use this in production unless you have completed your own production test plan covering full restore validation, long-running stress tests, interrupted-backup tests, power-loss recovery tests, kernel upgrade tests, package uninstall cleanup, SELinux/AppArmor behavior, and bare-metal recovery tests. See [docs/production-test-plan.md](docs/production-test-plan.md).

## What This Repository Does Not Contain

This repository does not distribute Synology proprietary binaries.

Do not upload:

- Official Synology zip or deb files
- Generated deb packages containing Synology binaries
- NAS credentials, certificates, tokens, or unredacted logs

The build script downloads the official Synology package on your ARM64 machine, or uses a local official zip that you provide with `ABB_OFFICIAL_ZIP`.

## Validation Summary

The project has completed multiple ARM64 VM validation runs covering package
installation, native `synosnap` DKMS build/load, ABB registration through
Box64, whole-device backup, file restore, and checksum verification. These
results validate the core technical path, but they are not a complete
production-readiness certification.

The minimal PoC was validated on:

- Ubuntu 22.04.4 LTS
- ARM64 / aarch64
- Kernel 5.15.0-113-generic
- Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053
- synosnap 0.12.10 built natively with DKMS on ARM64

Validated checkpoints:

- Box64 runs x86_64 ABB userspace tools.
- ARM64 native synosnap DKMS loads.
- x86_64 `sbdctl` under Box64 can create and destroy `/dev/synosnap0`.
- ABB daemon connects to NAS.
- A safe custom-volume task for `/mnt/abb-scsi-test` completed first backup.
- A second backup used CBT/incremental mode and transferred about 8.5 MB.
- Restore to `/tmp/abb-restore-test` matched source sha256 hashes.

See [docs/test-report.md](docs/test-report.md).

Additional RPM VM validation was completed on 2026-04-30:

- Rocky Linux 9.7 ARM64 VM, kernel 5.14.0-611.49.1.el9_7.aarch64, SELinux Enforcing.
- Locally built RPM installed successfully with native ARM64 `synosnap` DKMS.
- `abb-box64.service` ran the official x86_64 ABB daemon through Box64.
- The agent registered to a private NAS test target.
- An Entire Device backup completed successfully.
- A single restored file matched the pre-delete MD5 checksum.

Additional Debian VM validation was completed on 2026-05-01:

- Debian 12 ARM64 VM, kernel 6.1.0-44-cloud-arm64.
- Locally built DEB installed successfully with native ARM64 `synosnap` DKMS.
- `abb-box64.service` ran the official x86_64 ABB daemon through Box64.
- The agent registered to a private NAS test target.
- An Entire Device backup completed successfully.
- A cloned Debian restore VM reused the compiled `synosnap` module without
  rebuilding DKMS.
- A single restored file matched the pre-restore SHA256 checksum.
- The cloned restore VM then completed its own first Entire Device backup.

This still does not make the project production ready. Bare-metal restore,
long-running stress, interruption, power-loss, kernel-upgrade, and uninstall
cleanup validation remain required before any production use.

## Install Deb On Debian/Ubuntu

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
git clone https://github.com/<your-name>/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
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

RPM support is experimental and should be tested in a disposable ARM64 RPM VM or spare host:

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

## Release Policy

Source-only releases are allowed. Do not attach generated `.deb` files, official Synology zip/deb files, extracted Synology files, NAS logs, or credentials to GitHub Releases.

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

During the PoC, x86_64 libmount under Box64 returned an empty mount table even though it opened and read `/proc/self/mountinfo`. This made the NAS custom-volume list empty. This repository includes a small x86_64 preload shim for the libmount functions ABB uses for mount enumeration. It is built locally with `x86_64-linux-gnu-gcc` during packaging and installed under:

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

The wrapper loads it through `BOX64_LD_PRELOAD` when present. This is a compatibility workaround and one of the reasons this project is not production-ready.

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
