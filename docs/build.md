# Build

Install build prerequisites:

```bash
sudo apt update
sudo apt install -y dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
```

Build using the default official Synology download URL:

```bash
sudo ./scripts/build-deb.sh
```

Build using a manually downloaded official zip:

```bash
ABB_OFFICIAL_ZIP=/path/to/Synology-ABB-Agent-x64-deb.zip sudo ./scripts/build-deb.sh
```

Expected output:

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

The generated deb contains Synology files extracted from the official package.
It is for local private use only. Do not upload it to GitHub.

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

