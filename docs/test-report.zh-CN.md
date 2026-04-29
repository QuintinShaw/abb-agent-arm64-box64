# 公开 PoC 测试报告

[English](test-report.md) | 中文

日期：2026-04-29

这是打码后的公开摘要。NAS 主机名、账号、token、设备 ID、证书、内网域名和真实磁盘 UUID 均已省略。

## 环境

- Ubuntu 22.04.4 LTS
- ARM64 / aarch64
- Kernel 5.15.0-113-generic
- Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053 x86_64 用户态
- `synosnap` 0.12.10 在 ARM64 上通过 DKMS 原生构建

## 摘要

PoC 完成了最小安全闭环：

```text
ARM64 native synosnap DKMS
  + Box64 x86_64 ABB userspace
  + NAS custom-volume task
  + first backup of a temporary test block device
  + CBT incremental backup
  + restore to a separate temporary path
  + sha256 verification
```

## 检查点

- CP1 synosnap ARM64 DKMS 编译/加载：PASS
- CP2 Box64 启动 x86_64 ABB 工具：PASS
- CP3 Box64 下的 x86_64 `sbdctl` 打通 ARM64 synosnap ioctl 路径：PASS
- CP4 daemon/systemd 生命周期 PoC：PASS，但有 caveat
- CP5 安全 NAS 自定义卷注册：PASS
- CP5A 首次测试备份：PASS
- CP5B 增量备份：PASS
- CP5C 恢复 sha256 校验：PASS

## 关键技术发现

Box64 可运行：

- `sbdctl`
- `abb-cli`
- `service-ctrl`
- `synology-backupd`

`sbdctl setup-snapshot` 针对测试块设备可创建 `/dev/synosnap0`。`sbdctl destroy` 可移除它。

ABB daemon 可连接 NAS，并成功处理只选择临时测试卷的自定义卷任务。

## Mount Enumeration 问题

ARM64 主机最初在 NAS 自定义卷列表中显示为空。排查发现：Box64 下的 x86_64 libmount 能打开并读取 mount 文件，但向 ABB 返回零条目。

一个小型 x86_64 preload shim 实现了 ABB 卷枚举用到的 libmount 函数，并在 PoC 中修复了自定义卷列表。

## 安全测试卷

使用了临时测试卷：

- 设备类型：temporary SCSI debug disk
- 文件系统：ext4
- Label：`ABBSCSITEST`
- 挂载点：`/mnt/abb-scsi-test`
- NAS 任务来源：仅 `/mnt/abb-scsi-test`

真实系统根目录 `/` 未被选择。未使用 Entire Device backup。

## 备份结果

首次备份：

- 为测试卷创建 snapshot。
- 上传卷内容。
- 任务成功完成。
- snapshot device 被清理。

增量备份：

- 修改源数据并新增 8 MiB 文件。
- ABB 使用 CBT/增量模式。
- NAS 报告成功，传输约 8.5 MB。

## 恢复校验

第二个版本被恢复到单独临时路径。三个测试数据文件与增量后的源 hash 对比。

结果：所有 sha256 hash 一致。

## 生产就绪度

不适合生产环境。

已知风险：

- PoC 当前依赖兼容性 mount shim。
- systemd 监督仍存在 daemonize 相关 caveat。
- 测试使用小型临时卷，不是真实生产负载。
- 未执行长时间压力测试。
- 未执行断电或备份中断恢复测试。
- 未执行多内核测试矩阵。
- 未执行完整裸机恢复。
