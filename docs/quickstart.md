# Quickstart

[English](quickstart.md) | [中文](quickstart.zh-CN.md)

For a first trial on a compatible ARM64 Linux system, use the quickstart script:

```bash
curl -L -o abb-agent-arm64-box64-source.tar.gz \
  https://github.com/QuintinShaw/abb-agent-arm64-box64/releases/latest/download/abb-agent-arm64-box64-source.tar.gz
tar -xzf abb-agent-arm64-box64-source.tar.gz
cd abb-agent-arm64-box64-*
./scripts/quickstart.sh --yes
```

After installation, connect the agent to your NAS:

```bash
sudo abb-cli -c
```

Or let quickstart start the connection step after installation:

```bash
./scripts/quickstart.sh --yes --connect
```

The script:

- Verifies the system is ARM64.
- Installs build and DKMS prerequisites.
- Installs Box64 automatically on Debian/Ubuntu when missing.
- Uses a distro Box64 package on Fedora when available.
- Requires a preinstalled compatible Box64 on Rocky/RHEL-like systems if no
  trusted distro package is available.
- Builds a local DEB or RPM from Synology's official package input.
- Installs the generated local package.
- Enables and starts `abb-box64.service`.
- Runs the read-only preflight checker.

The generated package contains Synology proprietary files extracted locally
from the official package. Do not upload it or attach it to GitHub Releases.

The release source archive contains only repository source files, docs, scripts,
and packaging metadata. It does not contain generated packages or Synology
official binaries.

## Manual Official Archive

DEB:

```bash
./scripts/quickstart.sh --yes \
  --official-zip /path/to/official-deb.zip \
  --official-sha256 <sha256>
```

RPM:

```bash
./scripts/quickstart.sh --yes --package rpm \
  --official-rpm-zip /path/to/official-rpm.zip \
  --official-rpm-sha256 <sha256>
```

## RPM Note

RPM systems need a Box64 binary compatible with the target distro glibc and
x86_64 runtime libraries. Do not copy a Box64 binary from another distro unless
you have verified compatibility.
