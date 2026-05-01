# Public Validation Report

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

The initial ARM64 host validation completed a safe custom-volume loop:

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
- CP4 daemon/systemd lifecycle: PASS with notes
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
volume enumeration fixed the custom-volume list during validation.

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

## Beta Scope

The project is in beta testing. The runs below validate the core ARM64 path,
but deployment decisions should still be based on a target-environment test
plan.

Remaining validation work:

- The project currently depends on a compatibility mount shim.
- systemd supervision still has daemonization notes to track.
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

Observed notes:

- The log showed two post-completion lines similar to
  `Failed to transition snpashot`.
- The final server-side task result and `abb-cli -s` status still reported
  completion.
- `synosnap` snapshot device use count returned to zero after the backup.

This RPM VM run improves confidence in RPM installation and basic
backup/restore behavior. It should be combined with target-environment checks
for bare-metal restore, long-running stress, interrupted backup recovery,
power-loss recovery, kernel upgrade survival, and uninstall cleanup.

## Debian VM Validation Addendum

Date: 2026-05-01

This addendum summarizes a separate Debian-based VM run. NAS hostnames,
accounts, tokens, device IDs, certificates, internal domains, and real UUIDs
are omitted.

Environment:

- Debian 12 ARM64 VM
- Kernel 6.1.0-44-cloud-arm64
- Box64 v0.4.2 built locally on a compatible ARM64 Debian/Ubuntu system
- Synology ABB Agent 3.2.0-5053 x86_64 userspace
- synosnap 0.12.10 built natively with DKMS on ARM64

Validated checkpoints:

- DEB build on ARM64: PASS
- DEB install in the Debian VM: PASS
- Native ARM64 synosnap DKMS compile/load: PASS
- systemd service start through Box64: PASS
- Private NAS registration: PASS
- Entire Device backup from the original Debian VM: PASS
- Single-file restore into a cloned Debian restore VM with SHA256 verification:
  PASS
- First Entire Device backup from the cloned restore VM: PASS

Original Debian VM backup result:

- The NAS task source type was Entire Device.
- The client created a snapshot for `/`.
- `/boot/efi` and `/` content were read and uploaded.
- The task completed successfully.
- The client status after completion was `Idle - Completed`.
- The reported protected data size was approximately 4.63 GB.
- `synosnap` snapshot device use count returned to zero after completion.

Restore VM result:

- A new Debian restore VM was created by copying the original Debian VM disk.
- The copied VM reused the already built `synosnap.ko` for the same kernel; DKMS
  was not rebuilt in the restore VM.
- `modprobe synosnap` succeeded in the restore VM.
- A single non-sensitive file was restored into a temporary directory.
- Restored SHA256 matched the pre-restore SHA256:

  ```text
  caf944063eb6261bc1c1a6a9f0c7b40d3842843044f3bce58824358f425be254
  ```

- The restore task completed successfully.

Restore VM first-backup result:

- A small marker file was created before the restore VM backup.
- Its SHA256 was recorded:

  ```text
  e960d77efe65259fc6b5cce1df904ab651adc89747ad9d334da8e33e212066e0
  ```

- The restore VM then completed its own first Entire Device backup.
- The reported protected data size was approximately 4.65 GB.
- This was the restore VM's first backup, not an incremental backup validation.
- The marker file SHA256 remained unchanged after the backup.
- `synosnap` snapshot device use count returned to zero after completion.

Observed notes:

- On the first boot of the cloned restore VM, `abb-box64.service` started before
  `synosnap` was loaded and the ABB daemon logged a kernel-driver check error.
  Loading `synosnap` and restarting the service fixed the check. The packaged
  service now runs `modprobe synosnap` before starting the daemon.
- The client log showed `Umount status = -1` during backup cleanup. The final
  task result and `abb-cli -s` status still reported completion, and `synosnap`
  use count returned to zero.
- A cloned VM can carry local snapshot-history state from the source VM. Treat
  clone-based restore VMs as disposable validation targets, and do not interpret
  their first backup as an incremental-backup result.

This Debian VM run improves confidence in DEB installation, whole-device
backup, file restore, and clone-based restore-environment behavior. It should
be combined with target-environment checks for bare-metal restore, long-running
stress, interrupted backup recovery, power-loss recovery, kernel upgrade
survival, and uninstall cleanup.
