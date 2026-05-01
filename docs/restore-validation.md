# Restore Validation

[English](restore-validation.md) | [中文](restore-validation.zh-CN.md)

Backup success is not enough. Validate restores before trusting any backup
stack.

Recommended minimum flow:

1. Create a temporary test volume or test directory.
2. Write deterministic and random files.
3. Save source hashes:

   ```bash
   find /path/to/source/data -type f -exec sha256sum {} \; | sort > /tmp/source.sha256
   ```

4. Create a NAS task that selects only the test scope.
5. Run a first backup.
6. Modify files and add a new file.
7. Save post-change hashes:

   ```bash
   find /path/to/source/data -type f -exec sha256sum {} \; | sort > /tmp/source.after.sha256
   ```

8. Run an incremental backup.
9. Restore the newest version to a separate temporary path.
10. Normalize paths and compare hashes:

   ```bash
   find /tmp/restore/data -type f -exec sha256sum {} \; \
     | sed -E 's#  /tmp/restore/#  #' \
     | sort > /tmp/restored.sha256

   sed -E 's#  /path/to/source/#  #' /tmp/source.after.sha256 \
     | sort > /tmp/source.normalized.sha256

   diff -u /tmp/source.normalized.sha256 /tmp/restored.sha256
   ```

Only treat the test as passed when `diff` exits with status 0.

## Clone-Based Restore VM Notes

For disposable validation, you can create a restore VM by copying a tested VM
disk. This can avoid rebuilding `synosnap` when the copied VM boots the same
kernel and already contains the matching DKMS-built module.

When using this approach:

- Keep the source VM shut down while copying its disk.
- Treat the cloned VM as a new disposable validation target.
- Confirm `modinfo synosnap`, `modprobe synosnap`, and `lsmod | grep synosnap`
  before starting a restore.
- Confirm `abb-box64.service` is `enabled` and `active`.
- Restore into a separate temporary path and compare hashes.
- Do not treat the clone's first backup as incremental validation. It is the
  cloned VM's own first backup unless it already has a valid backup chain as
  that same ABB device.

If the ABB daemon starts before the kernel module is loaded, restart the service
after loading `synosnap`. The packaged service runs `modprobe synosnap` before
starting the daemon to reduce this risk.
