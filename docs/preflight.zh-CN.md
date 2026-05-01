# 预检脚本

[English](preflight.md) | 中文

提交 issue 或开始备份测试前，建议先运行预检脚本：

```bash
./scripts/preflight-check.sh
```

该脚本只读，不会修改系统。它会输出系统信息，并检查常见前置条件：

- 是否为 ARM64 架构。
- `/lib/modules/$(uname -r)/build` 下是否有匹配的内核构建目录。
- DKMS、编译器、make、kmod、systemd 和包管理工具。
- Box64 版本和路径。
- 官方 ABB 二进制常用的 x86_64 运行库。
- 已安装的 `abb-agent-arm64-box64` 软件包状态，如有。
- `synosnap` DKMS 和内核模块加载状态。
- `abb-box64.service` 是否启用及运行状态。
- 工具存在时，输出 SELinux/AppArmor 状态。

预检脚本不会注册 NAS、创建任务、启动备份、安装软件包或改变 systemd 状态。

分享输出前请先打码：

- NAS 主机名和私有 IP。
- 账号名。
- token 和证书。
- 设备标识符和 UUID。
- 内网域名。
