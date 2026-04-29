# abb-agent-arm64-box64

通过 ARM64 原生 `synosnap` DKMS + Box64，在 ARM64 Linux 上运行 Synology Active Backup for Business Linux x86_64 Agent。

状态：Experimental / PoC / 不适合生产环境。

语言：[English](README.md) | 中文

本仓库不包含、也不再分发 Synology 二进制文件。

## 风险声明

本项目不是 Synology 官方项目，不受 Synology 支持，仅用于学习、研究和兼容性实验。备份软件必须通过恢复测试验证后才能被信任。你需要自行承担数据、NAS、服务器、内核和恢复方案风险。

除非你已经完成自己的生产测试计划，包括完整恢复验证、长时间压力测试、备份中断测试、断电恢复测试、内核升级测试、软件包卸载清理、SELinux/AppArmor 行为验证和裸机恢复测试，否则不要用于生产环境。详见 [docs/production-test-plan.zh-CN.md](docs/production-test-plan.zh-CN.md)。

## 本仓库不包含什么

本仓库不分发 Synology 专有二进制文件。

不要上传：

- Synology 官方 zip、deb 或 rpm 文件
- 包含 Synology 二进制文件的本地生成 deb/rpm 包
- NAS 凭据、证书、token 或未打码日志

构建脚本会在你的 ARM64 机器上下载 Synology 官方包，或者使用你通过 `ABB_OFFICIAL_ZIP` / `ABB_OFFICIAL_RPM_ZIP` 提供的本地官方 zip。

## 已测试 PoC 摘要

最小 PoC 已在以下环境验证：

- Ubuntu 22.04.4 LTS
- ARM64 / aarch64
- Kernel 5.15.0-113-generic
- Box64 v0.4.2
- Synology ABB Agent 3.2.0-5053
- `synosnap` 0.12.10 在 ARM64 上通过 DKMS 原生构建

已验证检查点：

- Box64 可运行 x86_64 ABB 用户态工具。
- ARM64 原生 `synosnap` DKMS 可加载。
- x86_64 `sbdctl` 经 Box64 可创建和销毁 `/dev/synosnap0`。
- ABB daemon 可连接 NAS。
- 面向 `/mnt/abb-scsi-test` 的安全自定义卷任务完成首次备份。
- 第二次备份使用 CBT/增量路径，传输约 8.5 MB。
- 恢复到 `/tmp/abb-restore-test` 后，源数据和恢复数据 sha256 一致。

详见 [docs/test-report.zh-CN.md](docs/test-report.zh-CN.md)。

## 在 Debian/Ubuntu 上安装 deb

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
git clone https://github.com/<your-name>/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
sudo ./scripts/install-box64.sh
./scripts/build-deb.sh
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
sudo systemctl start abb-box64.service
sudo abb-cli -c
```

服务不会自动开机启用。测试时手动启动：

```bash
sudo systemctl start abb-box64.service
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

RPM 支持是实验性的，应在一次性 ARM64 RPM 虚拟机或备用主机上测试：

```bash
./scripts/build-rpm.sh
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo abb-cli -s
```

RPM 构建器使用 Synology 官方 x86_64 rpm zip，并用内置 SHA256 校验默认下载。使用手动输入：

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/official-rpm.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh
```

详见 [docs/rpm.zh-CN.md](docs/rpm.zh-CN.md)。RPM 兼容需要分别验证 `kernel-devel`、DKMS、systemd、SELinux 和官方 rpm 包文件布局。

## 发布规则

只允许发布源码。不要向 GitHub Releases 附加生成的 `.deb` / `.rpm`、Synology 官方 zip/deb/rpm、解包后的 Synology 文件、NAS 日志或凭据。

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
7. 按相对路径比较恢复文件 hash 和源文件 hash。

详见 [docs/restore-validation.zh-CN.md](docs/restore-validation.zh-CN.md) 和 [examples/abb-test-loop-device.zh-CN.md](examples/abb-test-loop-device.zh-CN.md)。

面向生产的验证还应覆盖备份中断、强制重启、内核升级、软件包移除和 SELinux/AppArmor 行为。详见 [examples/production-test-checklist.zh-CN.md](examples/production-test-checklist.zh-CN.md)。

## 兼容性 Shim

PoC 中发现，Box64 下的 x86_64 `libmount.so.1` 即使能打开并读取 `/proc/self/mountinfo`，仍会返回空 mount table，导致 NAS 自定义卷列表为空。本仓库包含一个小型 x86_64 preload shim，实现 ABB 挂载点枚举所需的 libmount 函数子集。它会在打包时由 `x86_64-linux-gnu-gcc` 本地构建，并安装到：

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

wrapper 会在该文件存在时通过 `BOX64_LD_PRELOAD` 加载它。这只是兼容性 workaround，也是本项目不适合生产环境的原因之一。

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
