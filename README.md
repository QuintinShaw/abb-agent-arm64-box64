# abb-agent-arm64-box64

Run Synology Active Backup for Business Linux x86_64 Agent on ARM64 using native synosnap DKMS + Box64.

Status: Experimental / PoC / Not production ready.

## Risk Statement

This project is unofficial, unsupported by Synology, and intended only for learning, research, and interoperability experiments. Backup software must be validated by restore tests before it is trusted. You are responsible for your data, NAS, server, kernel, and recovery plan.

Do not use this in production unless you have completed your own full restore validation, long-running stress tests, interrupted-backup tests, power-loss recovery tests, kernel upgrade tests, and bare-metal recovery tests.

## What This Repository Does Not Contain

This repository does not distribute Synology proprietary binaries.

Do not upload:

- Official Synology zip or deb files
- Generated deb packages containing Synology binaries
- NAS credentials, certificates, tokens, or unredacted logs

The build script downloads the official Synology package on your ARM64 machine, or uses a local official zip that you provide with `ABB_OFFICIAL_ZIP`.

## Tested PoC Summary

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

## Install

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
git clone https://github.com/<your-name>/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
sudo ./scripts/install-box64.sh
sudo ./scripts/build-deb.sh
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
sudo systemctl start abb-box64.service
sudo abb-cli -c
```

The service is not enabled automatically. Start it manually when testing:

```bash
sudo systemctl start abb-box64.service
```

## Build

Default build downloads the official Synology zip:

```bash
sudo ./scripts/build-deb.sh
```

To use a manually downloaded official zip:

```bash
ABB_OFFICIAL_ZIP=/path/to/official.zip sudo ./scripts/build-deb.sh
```

Expected output:

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

This generated package is for your own local machine. Do not publish it to GitHub Releases because it contains Synology proprietary files extracted from the official package.

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

If you believe this project infringes your rights, contact `your_email@example.com`.

## References

- https://github.com/ardnew/synology-active-backup-business-agent
- https://github.com/Peppershade/abb-linux-agent-6.12
- https://github.com/ptitSeb/box64
- Synology official Active Backup for Business Agent download page

