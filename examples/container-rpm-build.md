# Container RPM Build Example

[English](container-rpm-build.md) | [中文](container-rpm-build.zh-CN.md)

This checks RPM package assembly in a container. It does not validate DKMS,
systemd, SELinux, backup, or restore behavior.

Build the container image:

```bash
podman build -f docker/Containerfile.rpm-build -t abb-rpm-build .
```

Run the build with a mounted workspace:

```bash
podman run --rm \
  -v "$PWD:/work:Z" \
  abb-rpm-build
```

For Docker on systems without SELinux relabeling:

```bash
docker run --rm \
  -v "$PWD:/work" \
  abb-rpm-build
```

This container is Debian-based on purpose: it provides `rpmbuild`,
`rpm2cpio`, and `x86_64-linux-gnu-gcc` without installing RPM tooling on the
host. The entrypoint copies the mounted checkout to a temporary container
directory, runs `scripts/build-rpm.sh` as the unprivileged `builder` user, and
copies only `dist/` back to the mounted workspace. It is only an assembly check
and should not be used as release evidence.

Install and run the generated rpm only inside a disposable ARM64 RPM VM or test
host:

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo abb-cli -s
```
