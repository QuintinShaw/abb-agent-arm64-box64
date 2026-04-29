# Public PoC Test Report

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

