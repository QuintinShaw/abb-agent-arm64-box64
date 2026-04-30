# Public PoC Test Report

[English](test-report.md) | [中文](test-report.zh-CN.md)

Date: 2026-04-29

This is a redacted public summary. NAS hostnames, accounts, tokens, device IDs,
certificates, internal domains, and real disk UUIDs are omitted.

## Environment

- Ubuntu 22.04.4 LTS
- ARM64 / aarch64
- Kernel 5.15.0-113-generic
- Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053 x86_64 userspace
- synosnap 0.12.10 built natively with DKMS on ARM64

## Summary

The PoC completed a minimal safe loop:

```text
ARM64 native synosnap DKMS
  + Box64 x86_64 ABB userspace
  + NAS custom-volume task
  + first backup of a temporary test block device
  + CBT incremental backup
  + restore to a separate temporary path
  + sha256 verification
```

## Checkpoints

- CP1 synosnap ARM64 DKMS compile/load: PASS
- CP2 Box64 starts x86_64 ABB tools: PASS
- CP3 x86_64 `sbdctl` under Box64 reaches ARM64 synosnap ioctl path: PASS
- CP4 daemon/systemd lifecycle for PoC: PASS with caveats
- CP5 safe NAS custom-volume registration: PASS
- CP5A first test backup: PASS
- CP5B incremental backup: PASS
- CP5C restore sha256 verification: PASS

## Key Technical Findings

Box64 could run:

- `sbdctl`
- `abb-cli`
- `service-ctrl`
- `synology-backupd`

`sbdctl setup-snapshot` against a test block device created `/dev/synosnap0`.
`sbdctl destroy` removed it.

The ABB daemon connected to the NAS and successfully processed a custom-volume
task that selected only a temporary test volume.

## Mount Enumeration Issue

The ARM64 host initially showed an empty NAS custom-volume list. Investigation
found that x86_64 libmount under Box64 opened and read mount files but returned
zero entries to ABB.

A small x86_64 preload shim implementing the libmount functions ABB used during
volume enumeration fixed the custom-volume list for the PoC.

## Safe Test Volume

A temporary test volume was used:

- Device class: temporary SCSI debug disk
- Filesystem: ext4
- Label: `ABBSCSITEST`
- Mount point: `/mnt/abb-scsi-test`
- NAS task source: `/mnt/abb-scsi-test` only

The real system root `/` was not selected. Entire Device backup was not used.

## Backup Results

First backup:

- Snapshot created for the test volume.
- Volume content uploaded.
- Task completed successfully.
- Snapshot device was cleaned up.

Incremental backup:

- Source data was modified and a new 8 MiB file was added.
- ABB used CBT/incremental mode.
- NAS reported success and approximately 8.5 MB transferred.

## Restore Verification

The second version was restored to a separate temporary path. Three test data
files were compared against the post-incremental source hashes.

Result: all sha256 hashes matched.

## Production Readiness

Not production ready.

Known risks:

- The PoC currently depends on a compatibility mount shim.
- systemd supervision still has daemonization caveats.
- The test used a small temporary volume, not a real production workload.
- No long-duration stress test was performed.
- No power-loss or interrupted-backup recovery test was performed.
- No multi-kernel test matrix was performed.
- No full bare-metal restore was performed.

## RPM VM Validation Addendum

Date: 2026-04-30

This addendum summarizes a separate RPM-based VM run. NAS hostnames, accounts,
tokens, device IDs, certificates, internal domains, and real UUIDs are omitted.

Environment:

- Rocky Linux 9.7 ARM64 VM
- Kernel 5.14.0-611.49.1.el9_7.aarch64
- SELinux Enforcing
- Box64 v0.4.2 built locally for the target distro
- Synology ABB Agent 3.2.0-5053 x86_64 userspace
- synosnap 0.12.10 built natively with DKMS on ARM64

Validated checkpoints:

- RPM assembly in a container: PASS
- RPM install in the Rocky VM: PASS
- Native ARM64 synosnap DKMS compile/load: PASS
- systemd service start through Box64: PASS
- Private NAS registration: PASS
- Entire Device backup: PASS
- Single-file restore with MD5 verification: PASS

Important packaging finding:

- The official Synology RPM archive places `abb-cli` at `/bin/abb-cli`, not
  under `/opt/Synology/ActiveBackupforBusiness/bin`.
- The wrapper package used for this run had not copied that location yet, so
  local registration testing temporarily used `abb-cli` extracted from
  Synology's official DEB archive.
- The builder now relocates the official RPM `abb-cli` into the local ABB
  payload. Do not redistribute the binary or any generated package containing
  it.

Backup result:

- The NAS task source type was Entire Device.
- The client created snapshots for `/boot` and `/`.
- `/boot/efi`, `/boot`, and `/` content were read and uploaded.
- The task completed successfully.
- The client status after completion was `Idle - Completed`.
- The reported transferred size was approximately 1.43 GB.

Restore result:

- A non-sensitive test script was deleted from the VM after backup.
- The file was restored from ABB.
- Restored MD5 matched the pre-delete MD5:

  ```text
  41aa574c771a8671fe089b83ba890a5c
  ```

Observed caveats:

- The log showed two post-completion lines similar to
  `Failed to transition snpashot`.
- The final server-side task result and `abb-cli -s` status still reported
  completion.
- `synosnap` snapshot device use count returned to zero after the backup.

This RPM VM run improves confidence in RPM installation and basic
backup/restore behavior, but it is still not production validation. It did not
cover bare-metal restore, long-running stress, interrupted backup recovery,
power-loss recovery, kernel upgrade survival, or uninstall cleanup.
