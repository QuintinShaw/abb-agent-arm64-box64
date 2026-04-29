# Build

[English](build.md) | [中文](build.zh-CN.md)

Install build prerequisites:

```bash
sudo apt update
sudo apt install -y dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
```

Install Box64 separately, or use the convenience helper:

```bash
sudo BOX64_REF=v0.4.2 ./scripts/install-box64.sh
```

The helper pins Box64 to `v0.4.2` by default and builds as `SUDO_USER` when
available. For stricter supply-chain requirements, install Box64 through your
own pinned package or audited build pipeline.

Build using the default official Synology download URL:

```bash
./scripts/build-deb.sh
```

Build using a manually downloaded official zip:

```bash
ABB_OFFICIAL_ZIP=/path/to/Synology-ABB-Agent-x64-deb.zip ABB_OFFICIAL_SHA256=<sha256> ./scripts/build-deb.sh
```

`build-deb.sh` must run as an unprivileged user. It refuses root by default
because it downloads and extracts external packages. Install the generated deb
with `sudo dpkg -i` after the build completes.

The default official zip is verified with the SHA256 pinned in the script. When
using `ABB_OFFICIAL_ZIP`, provide `ABB_OFFICIAL_SHA256` unless you are doing a
disposable local experiment and explicitly set `ABB_ALLOW_UNVERIFIED_ZIP=1`.

Expected output:

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

The generated deb contains Synology files extracted from the official package.
It is for local private use only. Do not upload it to GitHub.

## RPM Build

RPM support uses Synology's official x86_64 rpm zip:

```bash
./scripts/build-rpm.sh
```

Manual official rpm zip:

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/Synology-ABB-Agent-x64-rpm.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh
```

Expected output:

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

Install and validate the RPM only in a disposable RPM VM or spare test host.
See [rpm.md](rpm.md) and [production-test-plan.md](production-test-plan.md).

## Build Inputs

The script expects the official zip to contain:

- Synology Active Backup for Business Agent deb
- synosnap deb

The script extracts:

- `/opt/Synology/ActiveBackupforBusiness`
- `synosnap` DKMS source into `/usr/src/synosnap-0.12.10`
- x86_64 `libsynosnap.so` into `/usr/lib/synosnap`

It also installs community files:

- `/usr/local/bin/abb-box64-wrapper`
- `/usr/local/bin/abb-cli`
- `/usr/local/bin/service-ctrl`
- `/usr/local/bin/sbdctl`
- `/etc/systemd/system/abb-box64.service`
- `/usr/local/lib/abb-agent-arm64-box64/mount_shim.so`
