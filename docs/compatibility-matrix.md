# Compatibility Matrix

[English](compatibility-matrix.md) | [中文](compatibility-matrix.zh-CN.md)

This matrix tracks public validation status for ARM64 systems. Add only results
that were tested from locally built packages and redacted logs.

Legend:

- PASS: tested successfully.
- PARTIAL: package or service validation passed, but backup/restore was not
  completed.
- TODO: not yet tested.
- N/A: not applicable to that environment.

## Validation Results

| Platform | Kernel | Package | Box64 | Install | Service | Backup | Restore | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ubuntu 22.04.4 ARM64 | 5.15.0-113-generic | Local DEB-style validation | v0.4.2 | PASS | PASS | PASS custom volume + incremental | PASS sha256 | Initial safe custom-volume validation. |
| Rocky Linux 9.7 ARM64 VM | 5.14.0-611.49.1.el9_7.aarch64 | Local RPM | v0.4.2 built for target distro | PASS | PASS | PASS Entire Device | PASS MD5 single file | SELinux Enforcing. Needs distro-compatible Box64 and x86_64 runtime libraries. |
| Debian 12 ARM64 VM | 6.1.0-44-cloud-arm64 | Local DEB | v0.4.2 built on compatible Debian/Ubuntu ARM64 | PASS | PASS | PASS Entire Device | PASS SHA256 single file | Restore VM reused the same-kernel `synosnap.ko` without DKMS rebuild. |

## Distro Notes

| Distribution family | Current notes |
| --- | --- |
| Debian/Ubuntu | Install matching `linux-headers-$(uname -r)`, DKMS, build tools, and a compatible Box64. |
| Rocky/RHEL-like | Install EPEL or another trusted DKMS source, matching `kernel-devel-$(uname -r)`, `elfutils-libelf-devel`, and a Box64 build compatible with the distro glibc. |
| Fedora | Box64 may be available from distro packages. Validate glibc and x86_64 runtime-library compatibility before ABB service testing. |

## Add A Result

When reporting a new result, include:

- Distribution and version.
- Kernel version.
- Package type and ABB Agent version.
- Box64 version and install method.
- Whether `synosnap` DKMS built and loaded.
- Whether NAS registration, backup, and restore were tested.
- Restore checksum result.
- Redacted notes for SELinux/AppArmor, service behavior, and snapshot cleanup.

Do not include private NAS hostnames, account names, tokens, certificates,
device identifiers, or generated packages.
