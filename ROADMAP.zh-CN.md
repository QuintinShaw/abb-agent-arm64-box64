# 路线图

[English](ROADMAP.md) | 中文

项目处于 beta 测试阶段。近期目标是把已经跑通的验证结果整理成可重复、可排查、文档清晰的安装和恢复流程，覆盖常见 ARM64 Linux 发行版。

## 当前重点

- 保持 DEB 和 RPM 本地构建器可从已校验的 Synology 官方包输入构建。
- 让 Debian、Ubuntu、Rocky、AlmaLinux 和 Fedora ARM64 的安装路径更可预期。
- 改进预检脚本，让用户在备份测试前发现缺失的内核头文件、DKMS、Box64、x86_64 运行库和服务问题。
- 收集更多真实 ARM64 主机和 VM 的整机备份、文件恢复结果。
- README 保持简洁，详细证据放到对应文档。

## 仍需验证

- 更多 ARM64 硬件：Raspberry Pi、Ampere、Graviton、RK3588、Apple Silicon Linux VM 和 ARM64 NAS 主板。
- 更多发行版和内核：Debian 12/13、Ubuntu 22.04/24.04、Rocky 9、AlmaLinux 9、Fedora 和厂商内核。
- 内核升级后的可用性：DKMS 重建、重启、服务启动、备份和恢复。
- 备份中断恢复：daemon 重启、网络中断、强制重启和遗留 snapshot 清理。
- 长时间备份/恢复循环及校验和比对。
- SELinux 和 AppArmor 对服务启动、ABB 日志、socket、Box64 和 `/dev/synosnap*` 的影响。
- 软件包卸载清理，同时不删除用户数据或 NAS 端状态。
- 条件允许时，补充裸机或磁盘级恢复流程。

## 适合第一次贡献的任务

- 向 `docs/compatibility-matrix.zh-CN.md` 添加一条验证结果。
- 改进某个发行版的安装说明。
- 提供打码后的失败日志和清晰复现步骤。
- 为某个发行版改进预检脚本。
- 补齐遗漏的中文或英文文档更新。
- 确认某个 Box64 包是否兼容特定 RPM 发行版。

## 发布方向

Release 只发布源码。生成的软件包和 Synology 官方下载包不得附加到 GitHub Releases。

打源码 tag 前：

- 更新兼容性矩阵。
- 将新增验证证据补充到测试报告。
- 运行 shell 语法检查和 `git diff --check`。
- 确认忽略的本地产物没有被跟踪。
- 复查 README、法律说明和安全说明的当前表述。
