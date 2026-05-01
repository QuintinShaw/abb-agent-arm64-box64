# 快速开始

[English](quickstart.md) | 中文

在兼容的 ARM64 Linux 系统上首次试用时，可以直接运行快速安装脚本：

```bash
git clone https://github.com/QuintinShaw/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
./scripts/quickstart.sh --yes
```

安装完成后，将 agent 连接到 NAS：

```bash
sudo abb-cli -c
```

也可以让快速安装脚本在安装完成后直接进入连接流程：

```bash
./scripts/quickstart.sh --yes --connect
```

该脚本会：

- 确认系统是 ARM64。
- 安装构建和 DKMS 前置依赖。
- 在 Debian/Ubuntu 上缺少 Box64 时自动安装 Box64。
- 在 Fedora 上优先使用发行版提供的 Box64 包。
- 在 Rocky/RHEL-like 系统上，如果没有可信发行版包，则要求你先安装与该发行版兼容的 Box64。
- 从 Synology 官方包输入构建本地 DEB 或 RPM。
- 安装生成的本地软件包。
- 启用并启动 `abb-box64.service`。
- 运行只读预检脚本。

生成的软件包包含从官方包本地提取的 Synology 专有文件。不要上传该软件包，也不要把它附加到 GitHub Releases。

## 手动指定官方压缩包

DEB：

```bash
./scripts/quickstart.sh --yes \
  --official-zip /path/to/official-deb.zip \
  --official-sha256 <sha256>
```

RPM：

```bash
./scripts/quickstart.sh --yes --package rpm \
  --official-rpm-zip /path/to/official-rpm.zip \
  --official-rpm-sha256 <sha256>
```

## RPM 注意事项

RPM 系统需要与目标发行版 glibc 兼容的 Box64，以及官方 ABB 二进制所需的 x86_64 运行库。不要直接复制其他发行版的 Box64，除非已经确认兼容。
