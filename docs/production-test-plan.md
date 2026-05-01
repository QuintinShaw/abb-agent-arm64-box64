# Production-Oriented Test Plan

[English](production-test-plan.md) | [中文](production-test-plan.zh-CN.md)

This project is in beta testing. A production decision should be based on the
matrix below, run on hardware and kernels that match the intended deployment.

## Release Gates

Do not treat a build as production-capable unless all gates are green:

- Build is reproducible from a verified official Synology package hash.
- Package installs and uninstalls cleanly on each target distribution.
- `synosnap` DKMS builds, loads, unloads, and rebuilds after kernel upgrades.
- `abb-box64.service` starts, stops, restarts, and survives daemon forking.
- NAS registration uses only an explicitly scoped test task.
- First backup, incremental backup, interrupted backup, and restore all pass.
- Restored data matches source hashes by relative path and SHA256.
- Power-loss or forced-reboot recovery leaves no stale snapshot device.
- Logs contain no NAS credentials, tokens, certificate material, or private hostnames.

## Build And Install Matrix

| Area | Debian/Ubuntu deb | RPM family rpm |
| --- | --- | --- |
| Builder host | Ubuntu 22.04/24.04 ARM64 | Rocky/Alma/Fedora ARM64 |
| Package input | Official x64 deb zip | Official x64 rpm zip |
| Build command | `./scripts/build-deb.sh` | `./scripts/build-rpm.sh` |
| Package output | `dist/*_arm64.deb` | `dist/*.aarch64.rpm` |
| Build tools | `dpkg-deb`, `unzip`, `gcc-x86-64-linux-gnu` | `rpmbuild`, `rpm2cpio`, `cpio`, `gcc-x86-64-linux-gnu` |
| Kernel headers | `linux-headers-$(uname -r)` | `kernel-devel-$(uname -r)` |
| Runtime service | systemd | systemd |
| MAC policy | AppArmor if enabled | SELinux if enforcing |

Record for every run:

```bash
uname -a
uname -m
cat /etc/os-release
box64 --version
dkms status synosnap || true
systemctl status abb-box64.service --no-pager || true
```

## Container Or VM Policy

Use containers only for source extraction, package assembly, and script linting.
Do not count container-only results as DKMS or backup validation because the
container normally shares the host kernel and may not run systemd.

Use disposable VMs or spare bare-metal systems for:

- DKMS build/load tests.
- `systemctl start/stop/restart abb-box64.service`.
- NAS registration.
- backup, restore, interruption, and reboot tests.
- SELinux enforcing-mode tests on RPM distributions.

## Backup And Restore Matrix

| Test | Required result |
| --- | --- |
| First backup | NAS shows success and journal has no daemon crash |
| Incremental backup | Changed files are included and unchanged files remain restorable |
| Hash restore | Restored files match source SHA256 by relative path |
| Interrupted backup | Kill daemon or disconnect network, then rerun backup successfully |
| Forced reboot | Reboot during idle and during backup, verify no stale `/dev/synosnap*` |
| NAS disconnect | Stop network temporarily, verify service recovers without credential leak |
| Snapshot cleanup | `sbdctl destroy` or daemon cleanup removes test snapshots |
| Uninstall | Package removal stops service and does not delete user/NAS data |

Use only temporary test disks, loop devices, or dedicated scratch volumes. Never
validate with a real production root filesystem.

## Kernel Upgrade Test

For each target distribution:

1. Install the package and confirm `synosnap` is loaded.
2. Upgrade to a newer supported kernel and matching headers.
3. Reboot.
4. Confirm DKMS rebuilt the module.
5. Confirm `modprobe synosnap` succeeds.
6. Run first and incremental backup again.
7. Restore and compare SHA256 hashes.

## RPM-Specific Validation

RPM compatibility is not proven by building an `.rpm`. Validate on each target
RPM distribution:

- Official rpm zip layout still contains ABB agent rpm and synosnap rpm.
- `rpm2cpio` extraction places files under expected paths.
- Generated rpm owns `/opt/Synology/ActiveBackupforBusiness`,
  `/usr/src/synosnap-0.12.10`, `/usr/lib/synosnap`, wrappers, and service file.
- `%post` DKMS build succeeds with the installed `kernel-devel`.
- systemd recognizes `Type=forking` and PID tracking.
- SELinux enforcing mode does not block Box64, ABB, DKMS, `/dev/synosnap*`, or
  ABB log/socket paths.
- Uninstall removes DKMS registration but does not delete NAS-side state.

Collect SELinux denials:

```bash
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -t setroubleshoot --no-pager || true
```

## Evidence Bundle

Keep a redacted evidence bundle per test run:

- system information.
- package build log.
- install/removal log.
- `dkms status` and `modinfo synosnap`.
- `systemctl status` and `journalctl -u abb-box64.service`.
- NAS task name with sensitive fields redacted.
- source and restored SHA256 files.
- `lsblk`, `findmnt`, and test volume details.
- SELinux/AppArmor denials if applicable.

Do not publish generated packages, official Synology packages, extracted
Synology files, NAS credentials, unredacted logs, or real disk identifiers.
