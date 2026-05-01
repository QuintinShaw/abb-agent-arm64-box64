# Safe Test Loop Device Example

[English](abb-test-loop-device.md) | [中文](abb-test-loop-device.zh-CN.md)

This example creates a temporary local block device for backup testing. Do not
select `/` or Entire Device backup in the NAS UI.

```bash
sudo mkdir -p /mnt/abb-loop-test
sudo fallocate -l 2G /tmp/abb-testdisk.img
sudo losetup -fP /tmp/abb-testdisk.img
LOOPDEV="$(losetup -a | grep /tmp/abb-testdisk.img | cut -d: -f1)"
echo "LOOPDEV=$LOOPDEV"

sudo mkfs.ext4 -F "$LOOPDEV"
sudo mount "$LOOPDEV" /mnt/abb-loop-test

sudo mkdir -p /mnt/abb-loop-test/data
echo "abb arm64 box64 backup test $(date -Is)" | sudo tee /mnt/abb-loop-test/data/file1.txt
sudo dd if=/dev/urandom of=/mnt/abb-loop-test/data/random1.bin bs=1M count=16 status=progress
sudo find /mnt/abb-loop-test/data -type f -exec sha256sum {} \; | sudo tee /mnt/abb-loop-test/SHA256SUMS.initial
sync
```

After testing:

```bash
sudo umount /mnt/abb-loop-test
sudo losetup -d "$LOOPDEV"
sudo rm -f /tmp/abb-testdisk.img
sudo rmdir /mnt/abb-loop-test
```

Depending on ABB/NAS behavior, loop devices may not appear as custom volumes.
Validation used a temporary SCSI debug disk when loop devices were not
sufficient.
