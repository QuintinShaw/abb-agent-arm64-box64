# 构建

[English](build.md) | 中文

安装构建依赖：

```bash
sudo apt update
sudo apt install -y dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
```

单独安装 Box64，或使用便捷辅助脚本：

```bash
sudo BOX64_REF=v0.4.2 ./scripts/install-box64.sh
```

该辅助脚本默认固定 Box64 到 `v0.4.2`，有 `SUDO_USER` 时会以该用户构建。若供应链要求更严格，请通过你自己的固定版本包或审计过的构建流水线安装 Box64。

使用默认 Synology 官方下载 URL 构建：

```bash
./scripts/build-deb.sh
```

使用手动下载的官方 zip 构建：

```bash
ABB_OFFICIAL_ZIP=/path/to/Synology-ABB-Agent-x64-deb.zip ABB_OFFICIAL_SHA256=<sha256> ./scripts/build-deb.sh
```

`build-deb.sh` 必须以非特权用户运行。脚本默认拒绝 root，因为它会下载并解包外部包。构建完成后再用 `sudo dpkg -i` 安装生成的 deb。

默认官方 zip 会用脚本内置 SHA256 校验。使用 `ABB_OFFICIAL_ZIP` 时应提供 `ABB_OFFICIAL_SHA256`；只有一次性本地验证才建议显式设置 `ABB_ALLOW_UNVERIFIED_ZIP=1`。

预期输出：

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

生成的 deb 包含从官方包提取的 Synology 文件，只供本地私有使用。不要上传到 GitHub。

## RPM 构建

RPM 支持使用 Synology 官方 x86_64 rpm zip：

```bash
./scripts/build-rpm.sh
```

手动指定官方 rpm zip：

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/Synology-ABB-Agent-x64-rpm.zip ABB_OFFICIAL_RPM_SHA256=<sha256> ./scripts/build-rpm.sh
```

预期输出：

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

只在一次性 RPM VM 或备用测试主机上安装和验证 RPM。详见 [rpm.zh-CN.md](rpm.zh-CN.md) 和 [production-test-plan.zh-CN.md](production-test-plan.zh-CN.md)。

## 构建输入

脚本期望官方 zip 包含：

- Synology Active Backup for Business Agent deb/rpm
- `synosnap` deb/rpm

脚本会提取：

- `/opt/Synology/ActiveBackupforBusiness`
- `synosnap` DKMS 源码到 `/usr/src/synosnap-0.12.10`
- x86_64 `libsynosnap.so` 到 `/usr/lib/synosnap`

同时安装社区文件：

- `/usr/local/bin/abb-box64-wrapper`
- `/usr/local/bin/abb-cli`
- `/usr/local/bin/service-ctrl`
- `/usr/local/bin/sbdctl`
- `/etc/systemd/system/abb-box64.service`
- `/usr/local/lib/abb-agent-arm64-box64/mount_shim.so`
