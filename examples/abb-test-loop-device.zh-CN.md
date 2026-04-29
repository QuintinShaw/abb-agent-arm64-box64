# 安全测试 Loop 设备示例

[English](abb-test-loop-device.md) | 中文

本示例创建一个临时本地块设备用于备份测试。不要在 NAS UI 里选择 `/` 或 Entire Device backup。

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

测试后：

```bash
sudo umount /mnt/abb-loop-test
sudo losetup -d "$LOOPDEV"
sudo rm -f /tmp/abb-testdisk.img
sudo rmdir /mnt/abb-loop-test
```

取决于 ABB/NAS 行为，loop 设备可能不会显示为自定义卷。PoC 中 loop 设备不足时使用了临时 SCSI debug disk。
