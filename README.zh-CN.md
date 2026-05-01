# abb-agent-arm64-box64

通过 ARM64 原生 `synosnap` DKMS + Box64，在 ARM64 Linux 上运行 Synology Active Backup for Business Linux x86_64 Agent。

状态：Beta 测试阶段。ARM64 VM 核心备份/恢复验证已通过。

语言：[English](README.md) | 中文

本仓库不包含、也不分发 Synology 二进制文件。

| 项目 | 状态 |
| --- | --- |
| DEB 打包 | Beta，已在 ARM64 Debian/Ubuntu 风格系统验证 |
| RPM 打包 | Beta，已在 Rocky Linux 9.7 ARM64 VM 验证 |
| 备份/恢复 | 已在 ARM64 VM 完成整机备份和文件恢复验证 |
| Release | 只发布源码；不发布 Synology 二进制文件或生成包 |

## Beta 说明

本项目不是 Synology 官方项目，不受 Synology 支持。项目已完成核心 ARM64
VM 备份/恢复验证，并进入 beta 测试阶段。你可以在兼容的 ARM64 Linux 系统上
尝试安装；如果遇到问题，请在 GitHub issue 中提供已打码日志、发行版/内核、
软件包类型和复现步骤。

备份软件仍必须在你自己的环境中完成恢复验证后再承载重要数据。请保留独立
恢复路径，并执行你自己的恢复测试。详见
[docs/production-test-plan.zh-CN.md](docs/production-test-plan.zh-CN.md)。

## 快速开始

在兼容的 ARM64 Linux 系统上，最低门槛的试用路径：

```bash
curl -L -o abb-agent-arm64-box64-source.tar.gz \
  https://github.com/QuintinShaw/abb-agent-arm64-box64/releases/latest/download/abb-agent-arm64-box64-source.tar.gz
tar -xzf abb-agent-arm64-box64-source.tar.gz
cd abb-agent-arm64-box64-*
./scripts/quickstart.sh --yes
sudo abb-cli -c
```

快速安装脚本会安装前置依赖，从 Synology 官方包输入构建本地软件包，安装该
软件包，启用 `abb-box64.service`，并运行只读预检。它不会重新分发 Synology
二进制文件。

详见 [docs/quickstart.zh-CN.md](docs/quickstart.zh-CN.md)、
[docs/preflight.zh-CN.md](docs/preflight.zh-CN.md) 和
[docs/compatibility-matrix.zh-CN.md](docs/compatibility-matrix.zh-CN.md)。

## 本仓库不包含什么

本仓库不分发 Synology 专有二进制文件。

不要上传：

- Synology 官方 zip、deb 或 rpm 文件
- 包含 Synology 二进制文件的本地生成 deb/rpm 包
- NAS 凭据、证书、token 或未打码日志

构建脚本会在你的 ARM64 机器上下载 Synology 官方包，或者使用你通过 `ABB_OFFICIAL_ZIP` / `ABB_OFFICIAL_RPM_ZIP` 提供的本地官方 zip。

## 验证摘要

项目已经完成 ARM64 VM 核心验证，覆盖 Debian/Ubuntu 风格 DEB 打包、RPM
打包、ARM64 原生 `synosnap` DKMS、基于 Box64 的 ABB 用户态、整机备份、
文件恢复和校验和比对。

详细结果见 [docs/test-report.zh-CN.md](docs/test-report.zh-CN.md)。

## 在 Debian/Ubuntu 上安装 deb

手动 DEB 路径：

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
curl -L -o abb-agent-arm64-box64-source.tar.gz \
  https://github.com/QuintinShaw/abb-agent-arm64-box64/releases/latest/download/abb-agent-arm64-box64-source.tar.gz
tar -xzf abb-agent-arm64-box64-source.tar.gz
cd abb-agent-arm64-box64-*
sudo ./scripts/install-box64.sh
./scripts/build-deb.sh
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
sudo systemctl enable --now abb-box64.service
sudo abb-cli -c
```

服务不会自动开机启用。测试时手动启用并启动：

```bash
sudo systemctl enable --now abb-box64.service
```

`install-box64.sh` 是便捷辅助脚本，默认 `BOX64_REF=v0.4.2`，有 `SUDO_USER` 时以该用户构建，只在安装依赖和最终安装时使用 root。你也可以自行安装 Box64。

## 构建

默认构建会下载 Synology 官方 zip：

```bash
./scripts/build-deb.sh
```

使用手动下载的官方 zip：

```bash
ABB_OFFICIAL_ZIP=/path/to/official.zip ABB_OFFICIAL_SHA256=<sha256> ./scripts/build-deb.sh
```

不要用 `sudo` 运行 `build-deb.sh`。构建阶段会下载并解包外部包，脚本会刻意以非特权用户运行。生成的 deb 再用 `sudo dpkg -i` 安装。

预期输出：

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

该包只供你本机私有使用。不要发布到 GitHub Releases，因为它包含从官方包中提取的 Synology 专有文件。

## 在 RPM 系统上构建 rpm

RPM 支持处于 beta 阶段，应在一次性 ARM64 RPM 虚拟机或备用主机上测试：

安装生成的 RPM 前，请先安装与发行版兼容的 Box64、来自 EPEL 或其他可信来源的 DKMS、当前运行内核对应的 `kernel-devel-$(uname -r)`，以及 Box64 所需的 x86_64 运行库。Rocky/RHEL 注意事项见 [docs/rpm.zh-CN.md](docs/rpm.zh-CN.md)。

```bash
./scripts/build-rpm.sh
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl enable --now abb-box64.service
sudo abb-cli -s
```

RPM 构建器使用 Synology 官方 x86_64 rpm zip，并用内置 SHA256 校验默认下载。使用手动输入：

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/official-rpm.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh
```

详见 [docs/rpm.zh-CN.md](docs/rpm.zh-CN.md)。RPM 兼容需要分别验证 `kernel-devel`、DKMS、systemd、SELinux 和官方 rpm 包文件布局。
Synology 官方 RPM 压缩包将 `abb-cli` 放在 `/bin/abb-cli`；本构建器会把这个官方二进制重新放入本地 ABB 文件树，让 `/usr/local/bin/abb-cli` 封装脚本可通过 Box64 工作。不要重新分发该二进制文件，也不要重新分发包含它的生成包。

## 反馈

可复现的安装、备份、恢复和发行版验证结果请提交 GitHub issue。安装讨论、成功验证记录和开放问题可以放到 GitHub Discussions。分享日志前请先打码。

有用链接：

- [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)
- [ROADMAP.zh-CN.md](ROADMAP.zh-CN.md)
- [docs/compatibility-matrix.zh-CN.md](docs/compatibility-matrix.zh-CN.md)
- [docs/test-report.zh-CN.md](docs/test-report.zh-CN.md)
- [SECURITY.zh-CN.md](SECURITY.zh-CN.md)

## 发布规则

只允许发布源码。Release 下载包由仓库中已跟踪的源码文件生成。不要向 GitHub
Releases 附加生成的 `.deb` / `.rpm`、Synology 官方 zip/deb/rpm、解包后的
Synology 文件、NAS 日志或凭据。

## 验证

```bash
lsmod | grep synosnap
systemctl status abb-box64.service --no-pager
abb-cli -s
```

然后在 NAS UI 确认 agent 在线。

## 恢复校验

最小安全验证流程：

1. 创建临时测试块设备或测试目录。
2. 生成测试文件并保存 `sha256sum` 输出。
3. 创建只选择测试范围的 NAS 任务。
4. 执行首次备份。
5. 修改测试数据并执行增量备份。
6. 恢复到另一个临时路径。
7. 按相对路径比较恢复文件和源文件的校验和。

详见 [docs/restore-validation.zh-CN.md](docs/restore-validation.zh-CN.md) 和 [examples/abb-test-loop-device.zh-CN.md](examples/abb-test-loop-device.zh-CN.md)。

面向生产的验证还应覆盖备份中断、强制重启、内核升级、软件包移除和 SELinux/AppArmor 行为。详见 [examples/production-test-checklist.zh-CN.md](examples/production-test-checklist.zh-CN.md)。

## 兼容性 Shim

验证期间发现，Box64 下的 x86_64 `libmount.so.1` 即使能打开并读取 `/proc/self/mountinfo`，仍会返回空 mount table，导致 NAS 自定义卷列表为空。本仓库包含一个小型 x86_64 preload shim，实现 ABB 挂载点枚举所需的 libmount 函数子集。它会在打包时由 `x86_64-linux-gnu-gcc` 本地构建，并安装到：

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

封装脚本会在该文件存在时通过 `BOX64_LD_PRELOAD` 加载它。这是 beta 阶段的兼容性变通方案。

## 法律说明

Synology 和 Active Backup for Business 是 Synology Inc. 的商标或注册商标。

本项目不隶属于 Synology Inc.，也未获得 Synology 官方支持。

本项目不分发 Synology 专有二进制文件。用户必须从 Synology 官方渠道获取相关软件包。本仓库脚本仅用于教育和互操作性研究目的。

如认为本项目侵犯你的权利，请联系 `github@xyt.email`。

## 参考

- https://github.com/ardnew/synology-active-backup-business-agent
- https://github.com/Peppershade/abb-linux-agent-6.12
- https://github.com/ptitSeb/box64
- Synology 官方 Active Backup for Business Agent 下载页
