# Container Notes

[English](README.md) | [中文](README.zh-CN.md)

Containers are useful for package assembly checks, but they are not sufficient
for production validation. `synosnap` is a kernel module, and backup behavior
depends on real block devices, systemd, NAS connectivity, and restore testing.

Use containers for:

- verifying scripts parse and extract official packages.
- checking rpm/deb package metadata.
- running shell syntax checks.

Use disposable VMs or spare physical hosts for:

- DKMS build/load/unload.
- systemd daemon lifecycle.
- SELinux/AppArmor.
- NAS registration.
- backup interruption, reboot, and restore hash tests.

See [Containerfile.rpm-build](Containerfile.rpm-build) and
[../examples/container-rpm-build.md](../examples/container-rpm-build.md) for a
container-only RPM assembly check.
