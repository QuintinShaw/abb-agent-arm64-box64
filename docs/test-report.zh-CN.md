# 公开验证报告

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

初始 ARM64 主机验证完成了安全的自定义卷闭环：

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
- CP4 daemon/systemd 生命周期：PASS，有待观察项
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

一个小型 x86_64 preload shim 实现了 ABB 卷枚举用到的 libmount 函数，并在验证中修复了自定义卷列表。

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

第二个版本被恢复到单独临时路径。三个测试数据文件与增量后的源文件校验和对比。

结果：所有 sha256 校验和一致。

## Beta 范围

项目处于 beta 测试阶段。下面的结果说明 ARM64 核心路径已经跑通，但是否用于具体环境，仍应以目标环境测试计划为准。

仍需补齐的验证：

- 项目当前依赖兼容性 mount shim。
- systemd 监督仍有 daemonize 相关行为需要持续观察。
- 测试使用小型临时卷，不是真实生产负载。
- 未执行长时间压力测试。
- 未执行断电或备份中断恢复测试。
- 未执行多内核测试矩阵。
- 未执行完整裸机恢复。

## RPM VM 验证补充

日期：2026-04-30

本节总结一次独立的 RPM 系 VM 验证。NAS 主机名、账号、token、设备 ID、证书、内网域名和真实 UUID 均已省略。

环境：

- Rocky Linux 9.7 ARM64 VM
- Kernel 5.14.0-611.49.1.el9_7.aarch64
- SELinux Enforcing
- 为目标发行版本地构建的 Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053 x86_64 用户态
- `synosnap` 0.12.10 在 ARM64 上通过 DKMS 原生构建

已验证检查点：

- 容器中 RPM 组装：PASS
- Rocky VM 中 RPM 安装：PASS
- ARM64 原生 `synosnap` DKMS 编译/加载：PASS
- 通过 Box64 启动 systemd 服务：PASS
- 注册到私有 NAS：PASS
- Entire Device 整机备份：PASS
- 单文件恢复及 MD5 校验：PASS

重要打包发现：

- Synology 官方 RPM 压缩包将 `abb-cli` 放在 `/bin/abb-cli`，不在 `/opt/Synology/ActiveBackupforBusiness/bin` 下。
- 本次运行使用的封装包当时还没有复制这个位置，因此本地注册测试临时使用了从 Synology 官方 DEB 压缩包提取的 `abb-cli`。
- 构建器现在会把官方 RPM 中的 `abb-cli` 重新放入本地 ABB 文件树。不得重新分发该二进制，也不得重新分发包含它的生成包。

备份结果：

- NAS 任务源类型为 Entire Device。
- 客户端为 `/boot` 和 `/` 创建 snapshot。
- `/boot/efi`、`/boot` 和 `/` 内容被读取并上传。
- 任务成功完成。
- 完成后客户端状态为 `Idle - Completed`。
- 报告传输量约 1.43 GB。

恢复结果：

- 备份后从 VM 删除了一个非敏感测试脚本。
- 该文件通过 ABB 恢复。
- 恢复后 MD5 与删除前一致：

  ```text
  41aa574c771a8671fe089b83ba890a5c
  ```

观察到的事项：

- 日志中出现两条收尾阶段记录，形如 `Failed to transition snpashot`。
- 最终服务端任务结果和 `abb-cli -s` 状态仍报告完成。
- 备份结束后 `synosnap` snapshot device use count 回到 0。

这次 RPM VM 验证提高了对 RPM 安装和基础备份/恢复行为的信心。实际部署前还应结合目标环境补充裸机恢复、长时间压力、备份中断恢复、断电恢复、内核升级存活和卸载清理等检查。

## Debian VM 验证补充

日期：2026-05-01

本节总结一次独立的 Debian 系 VM 验证。NAS 主机名、账号、token、设备 ID、证书、内网域名和真实 UUID 均已省略。

环境：

- Debian 12 ARM64 VM
- Kernel 6.1.0-44-cloud-arm64
- 在兼容的 ARM64 Debian/Ubuntu 系统上本地构建的 Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053 x86_64 用户态
- `synosnap` 0.12.10 在 ARM64 上通过 DKMS 原生构建

已验证检查点：

- ARM64 上 DEB 构建：PASS
- Debian VM 中 DEB 安装：PASS
- ARM64 原生 `synosnap` DKMS 编译/加载：PASS
- 通过 Box64 启动 systemd 服务：PASS
- 注册到私有 NAS：PASS
- 原 Debian VM 的 Entire Device 整机备份：PASS
- 在复制出的 Debian 恢复 VM 中完成单文件恢复及 SHA256 校验：PASS
- 复制出的恢复 VM 完成自己的首次 Entire Device 整机备份：PASS

原 Debian VM 备份结果：

- NAS 任务源类型为 Entire Device。
- 客户端为 `/` 创建 snapshot。
- `/boot/efi` 和 `/` 内容被读取并上传。
- 任务成功完成。
- 完成后客户端状态为 `Idle - Completed`。
- 报告受保护数据量约 4.63 GB。
- 备份结束后 `synosnap` snapshot device use count 回到 0。

恢复 VM 结果：

- 通过复制原 Debian VM 磁盘创建新的 Debian 恢复 VM。
- 复制出的 VM 复用了同一内核对应的已构建 `synosnap.ko`；恢复 VM 中没有重新构建 DKMS。
- 恢复 VM 中 `modprobe synosnap` 成功。
- 一个非敏感单文件被恢复到临时目录。
- 恢复后 SHA256 与恢复前一致：

  ```text
  caf944063eb6261bc1c1a6a9f0c7b40d3842843044f3bce58824358f425be254
  ```

- 恢复任务成功完成。

恢复 VM 首次备份结果：

- 恢复 VM 备份前创建了一个小型 marker 文件。
- 记录的 SHA256 为：

  ```text
  e960d77efe65259fc6b5cce1df904ab651adc89747ad9d334da8e33e212066e0
  ```

- 恢复 VM 随后完成了它自己的首次 Entire Device 整机备份。
- 报告受保护数据量约 4.65 GB。
- 这是恢复 VM 的首次备份，不是增量备份验证。
- 备份后 marker 文件 SHA256 保持不变。
- 备份结束后 `synosnap` snapshot device use count 回到 0。

观察到的事项：

- 复制出的恢复 VM 首次启动时，`abb-box64.service` 先于 `synosnap` 加载而启动，ABB daemon 记录了 kernel driver 检查错误。加载 `synosnap` 并重启服务后检查通过。打包的 service 现在会在启动 daemon 前执行 `modprobe synosnap`。
- 备份清理阶段客户端日志出现 `Umount status = -1`。最终任务结果和 `abb-cli -s` 状态仍报告完成，且 `synosnap` use count 回到 0。
- 克隆 VM 可能携带源 VM 的本地 snapshot-history 状态。应把基于克隆的恢复 VM 视为一次性验证目标，不要把它的首次备份解释为增量备份结果。

这次 Debian VM 验证提高了对 DEB 安装、整机备份、文件恢复和基于克隆的恢复环境行为的信心。实际部署前还应结合目标环境补充裸机恢复、长时间压力、备份中断恢复、断电恢复、内核升级存活和卸载清理等检查。
