# 安装

[English](install.md) | 中文

首次试用时，最快路径是快速安装脚本：

```bash
./scripts/quickstart.sh --yes
sudo abb-cli -c
```

参数和 RPM 注意事项见 [quickstart.zh-CN.md](quickstart.zh-CN.md)。

先构建本地 deb：

```bash
./scripts/build-deb.sh
```

不要用 `sudo` 运行构建步骤。它会以非特权用户下载并解包外部包。只在安装生成包时使用 `sudo`。

安装：

```bash
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
```

包的 post-install 步骤会：

- 检查 Box64 是否位于 `/usr/local/bin/box64` 或 `/usr/bin/box64`。
- 对 `synosnap/0.12.10` 执行 `dkms add/build/install`。
- 尝试 `modprobe synosnap`。
- 执行 `systemctl daemon-reload`。

服务不会自动启用。

手动启用并启动：

```bash
sudo systemctl enable --now abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

注册 NAS：

```bash
sudo abb-cli -c
```

查看状态：

```bash
sudo abb-cli -s
```

初次验证时不要接受 Entire Device 备份任务。只使用小型测试范围，并先完成恢复和校验和比对。
