# 兼容性矩阵

[English](compatibility-matrix.md) | 中文

本矩阵记录 ARM64 系统的公开验证状态。只添加来自本地构建包、且日志已打码的验证结果。

标记说明：

- PASS：已测试通过。
- PARTIAL：软件包或服务验证通过，但未完成备份/恢复。
- TODO：尚未测试。
- N/A：不适用于该环境。

## 验证结果

| 平台 | 内核 | 软件包 | Box64 | 安装 | 服务 | 备份 | 恢复 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ubuntu 22.04.4 ARM64 | 5.15.0-113-generic | 本地 DEB 路径验证 | v0.4.2 | PASS | PASS | PASS，自定义卷 + 增量 | PASS，sha256 | 初始安全自定义卷验证。 |
| Rocky Linux 9.7 ARM64 VM | 5.14.0-611.49.1.el9_7.aarch64 | 本地 RPM | 面向目标发行版本地构建的 v0.4.2 | PASS | PASS | PASS，Entire Device | PASS，单文件 MD5 | SELinux Enforcing。需要发行版兼容的 Box64 和 x86_64 运行库。 |
| Debian 12 ARM64 VM | 6.1.0-44-cloud-arm64 | 本地 DEB | 在兼容 Debian/Ubuntu ARM64 上构建的 v0.4.2 | PASS | PASS | PASS，Entire Device | PASS，单文件 SHA256 | 恢复 VM 复用了同内核的 `synosnap.ko`，没有重新构建 DKMS。 |

## 发行版说明

| 发行版系列 | 当前说明 |
| --- | --- |
| Debian/Ubuntu | 安装匹配的 `linux-headers-$(uname -r)`、DKMS、构建工具和兼容 Box64。 |
| Rocky/RHEL-like | 安装 EPEL 或其他可信 DKMS 来源、匹配的 `kernel-devel-$(uname -r)`、`elfutils-libelf-devel`，并使用与发行版 glibc 兼容的 Box64。 |
| Fedora | Box64 可能可由发行版包提供。测试 ABB 服务前仍需确认 glibc 和 x86_64 运行库兼容。 |

## 添加新结果

反馈新的验证结果时，请包含：

- 发行版和版本。
- 内核版本。
- 软件包类型和 ABB Agent 版本。
- Box64 版本和安装方式。
- `synosnap` DKMS 是否构建并加载。
- 是否测试了 NAS 注册、备份和恢复。
- 恢复校验和结果。
- SELinux/AppArmor、服务行为和 snapshot 清理的打码备注。

不要包含私有 NAS 主机名、账号、token、证书、设备标识符或生成的软件包。
