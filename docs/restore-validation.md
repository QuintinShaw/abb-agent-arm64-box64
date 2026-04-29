# Restore Validation

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

