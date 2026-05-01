# Roadmap

[English](ROADMAP.md) | [中文](ROADMAP.zh-CN.md)

This project is in beta testing. The immediate goal is to turn isolated working
validation runs into repeatable, well-documented install and restore workflows
across common ARM64 Linux distributions.

## Current Focus

- Keep DEB and RPM local builders working from verified official Synology
  package inputs.
- Make the install path predictable on Debian, Ubuntu, Rocky, AlmaLinux, and
  Fedora ARM64 systems.
- Improve preflight checks so users can identify missing kernel headers, DKMS,
  Box64, x86_64 runtime libraries, and service issues before backup testing.
- Collect more whole-device backup and file-restore results from real ARM64
  hosts and VMs.
- Keep README concise while moving detailed evidence into focused docs.

## Validation Needed

- More ARM64 hardware: Raspberry Pi, Ampere, Graviton, RK3588, Apple Silicon
  Linux VMs, and ARM64 NAS boards.
- More distributions and kernels: Debian 12/13, Ubuntu 22.04/24.04, Rocky 9,
  AlmaLinux 9, Fedora, and vendor kernels.
- Kernel upgrade survival: DKMS rebuild, reboot, service start, backup, and
  restore after the upgrade.
- Interrupted backup recovery: daemon restart, network loss, forced reboot, and
  stale snapshot cleanup.
- Long-running backup/restore loops with hash verification.
- SELinux and AppArmor observations for service start, ABB logs, sockets,
  Box64, and `/dev/synosnap*`.
- Package uninstall cleanup without deleting user/NAS-side data.
- Bare-metal or disk-level recovery workflows where the environment permits it.

## Good First Contributions

- Add a validation result to `docs/compatibility-matrix.md`.
- Improve distro-specific install notes.
- Add a redacted failure log with clear reproduction steps.
- Improve the preflight checker for a specific distribution.
- Add missing Chinese or English doc updates.
- Confirm whether a Box64 package is compatible with a specific RPM distro.

## Release Direction

Releases should remain source-only. Generated packages and official Synology
downloads must not be attached to GitHub Releases.

Before tagging a source release:

- Update the compatibility matrix.
- Update the test report with any new validation evidence.
- Run shell syntax checks and `git diff --check`.
- Confirm ignored local artifacts are not tracked.
- Review README, legal notes, and security notes for current wording.
