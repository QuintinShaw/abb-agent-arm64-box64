# Production Test Checklist Example

[English](production-test-checklist.md) | [中文](production-test-checklist.zh-CN.md)

Copy this checklist into a private test run note. Redact NAS addresses, account
names, certificates, tokens, and real disk identifiers before sharing results.

## Environment

- Host:
- Distribution:
- Kernel:
- Architecture:
- Box64 version:
- ABB package version:
- synosnap version:
- Package type: deb / rpm
- SELinux/AppArmor state:

## Build

```bash
./scripts/build-deb.sh
# or
./scripts/build-rpm.sh
```

Record:

```bash
sha256sum cache/official-abb-agent-*-x64-*.zip
ls -lh dist/
```

## Install

```bash
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
# or
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm

sudo systemctl start abb-box64.service
./scripts/verify-install.sh
```

Pass criteria:

- `synosnap` appears in `lsmod`.
- `abb-box64.service` stays active.
- `abb-cli -s` can contact the daemon.
- NAS sees the host online.

## Backup

Use a dedicated test volume only.

```bash
find /mnt/abb-test/data -type f -exec sha256sum {} \; | sort > /tmp/source.initial.sha256
```

Run the first backup from NAS.

Pass criteria:

- NAS reports success.
- No daemon crash in `journalctl -u abb-box64.service`.
- No stale `/dev/synosnap*` remains after completion unless ABB owns it.

## Incremental

```bash
date -Is | sudo tee -a /mnt/abb-test/data/file1.txt
sudo dd if=/dev/urandom of=/mnt/abb-test/data/random2.bin bs=1M count=8 status=progress
find /mnt/abb-test/data -type f -exec sha256sum {} \; | sort > /tmp/source.after.sha256
```

Run the second backup from NAS.

Pass criteria:

- NAS reports success.
- Changed files restore from the second version.

## Restore Hash

Restore to a separate path, never on top of the source.

```bash
find /tmp/abb-restore-test/data -type f -exec sha256sum {} \; \
  | sed -E 's#  /tmp/abb-restore-test/#  #' \
  | sort > /tmp/restored.sha256

sed -E 's#  /mnt/abb-test/#  #' /tmp/source.after.sha256 \
  | sort > /tmp/source.normalized.sha256

diff -u /tmp/source.normalized.sha256 /tmp/restored.sha256
```

Pass criteria:

- `diff` exits with status 0.

## Interruption

Run each interruption in a disposable VM:

- stop `abb-box64.service` during backup.
- disconnect test network during backup.
- force reboot during idle.
- force reboot during backup.

After each interruption:

```bash
sudo systemctl start abb-box64.service
ls -l /dev/synosnap* 2>/dev/null || true
dkms status synosnap || true
```

Pass criteria:

- service can start again.
- next backup succeeds.
- restore hash still matches.

## Kernel Upgrade

```bash
sudo apt install "linux-headers-$(uname -r)"
# or
sudo dnf install "kernel-devel-$(uname -r)"
```

After reboot into the new kernel:

```bash
dkms status synosnap
sudo modprobe synosnap
lsmod | grep synosnap
```

Pass criteria:

- DKMS rebuilds for the new kernel.
- backup and restore hash tests still pass.

## Uninstall

```bash
sudo systemctl stop abb-box64.service || true
sudo apt remove abb-agent-arm64-box64
# or
sudo dnf remove abb-agent-arm64-box64
```

Pass criteria:

- service is stopped.
- package removal does not delete user data or NAS-side backup data.
- purge/removal behavior is documented in the run note.
