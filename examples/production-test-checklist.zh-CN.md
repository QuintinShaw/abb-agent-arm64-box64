# 生产测试清单示例

[English](production-test-checklist.md) | 中文

把该清单复制到私有测试记录中。分享结果前打码 NAS 地址、账号、证书、token 和真实磁盘标识。

## 环境

- Host:
- Distribution:
- Kernel:
- Architecture:
- Box64 version:
- ABB package version:
- synosnap version:
- Package type: deb / rpm
- SELinux/AppArmor state:

## 构建

```bash
./scripts/build-deb.sh
# or
./scripts/build-rpm.sh
```

记录：

```bash
sha256sum cache/official-abb-agent-*-x64-*.zip
ls -lh dist/
```

## 安装

```bash
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
# or
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm

sudo systemctl enable --now abb-box64.service
./scripts/verify-install.sh
```

通过标准：

- `lsmod` 中出现 `synosnap`。
- `abb-box64.service` 保持 active。
- `abb-cli -s` 可以连接 daemon。
- NAS 看到主机在线。

## 备份

只使用专用测试卷。

```bash
find /mnt/abb-test/data -type f -exec sha256sum {} \; | sort > /tmp/source.initial.sha256
```

从 NAS 执行首次备份。

通过标准：

- NAS 报告成功。
- `journalctl -u abb-box64.service` 无 daemon crash。
- 完成后没有遗留未释放的 `/dev/synosnap*`，除非 ABB 仍拥有它。

## 增量

```bash
date -Is | sudo tee -a /mnt/abb-test/data/file1.txt
sudo dd if=/dev/urandom of=/mnt/abb-test/data/random2.bin bs=1M count=8 status=progress
find /mnt/abb-test/data -type f -exec sha256sum {} \; | sort > /tmp/source.after.sha256
```

从 NAS 执行第二次备份。

通过标准：

- NAS 报告成功。
- 变更文件可从第二个版本恢复。

## 恢复 Hash

恢复到单独路径，绝不要覆盖源数据。

```bash
find /tmp/abb-restore-test/data -type f -exec sha256sum {} \; \
  | sed -E 's#  /tmp/abb-restore-test/#  #' \
  | sort > /tmp/restored.sha256

sed -E 's#  /mnt/abb-test/#  #' /tmp/source.after.sha256 \
  | sort > /tmp/source.normalized.sha256

diff -u /tmp/source.normalized.sha256 /tmp/restored.sha256
```

通过标准：

- `diff` 退出状态为 0。

## 中断

每个中断测试都在一次性 VM 中运行：

- 备份过程中停止 `abb-box64.service`。
- 备份过程中断开测试网络。
- idle 时强制重启。
- 备份过程中强制重启。

每次中断后：

```bash
sudo systemctl start abb-box64.service
ls -l /dev/synosnap* 2>/dev/null || true
dkms status synosnap || true
```

通过标准：

- 服务可以重新启动。
- 下一次备份成功。
- 恢复文件校验和仍一致。

## 内核升级

```bash
sudo apt install "linux-headers-$(uname -r)"
# or
sudo dnf install "kernel-devel-$(uname -r)"
```

重启进入新内核后：

```bash
dkms status synosnap
sudo modprobe synosnap
lsmod | grep synosnap
```

通过标准：

- DKMS 为新内核重建。
- 备份和恢复校验和测试仍通过。

## 卸载

```bash
sudo systemctl stop abb-box64.service || true
sudo apt remove abb-agent-arm64-box64
# or
sudo dnf remove abb-agent-arm64-box64
```

通过标准：

- 服务已停止。
- 软件包移除不删除用户数据或 NAS 端备份数据。
- purge/removal 行为记录在测试笔记中。
