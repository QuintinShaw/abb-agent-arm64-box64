# Container Notes

[English](README.md) | [中文](README.zh-CN.md)

Containers are useful for package assembly checks, but they do not replace VM
or host validation. `synosnap` is a kernel module, and backup behavior depends
on real block devices, systemd, NAS connectivity, and restore testing.

Use containers for:

- verifying scripts parse and extract official packages.
- checking rpm/deb package metadata.
- running shell syntax checks.
- running package assembly as an unprivileged user inside an isolated container.

Use disposable VMs or spare physical hosts for:

- DKMS build/load/unload.
- systemd daemon lifecycle.
- SELinux/AppArmor.
- NAS registration.
- backup interruption, reboot, and restore hash tests.

See [Containerfile.rpm-build](Containerfile.rpm-build) and
[../examples/container-rpm-build.md](../examples/container-rpm-build.md) for a
container-only RPM assembly check. The image entrypoint copies the mounted
checkout to a temporary container directory, runs `scripts/build-rpm.sh` as the
unprivileged `builder` user, and copies only `dist/` back to the mounted
workspace.
