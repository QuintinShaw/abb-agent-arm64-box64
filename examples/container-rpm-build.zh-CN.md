# 容器 RPM 构建示例

[English](container-rpm-build.md) | 中文

本示例只在容器中检查 RPM 包组装。它不会验证 DKMS、systemd、SELinux、备份或恢复行为。

构建容器镜像：

```bash
podman build -f docker/Containerfile.rpm-build -t abb-rpm-build .
```

挂载工作区并运行构建：

```bash
podman run --rm \
  -v "$PWD:/work:Z" \
  abb-rpm-build
```

如果使用没有 SELinux relabel 需求的 Docker：

```bash
docker run --rm \
  -v "$PWD:/work" \
  abb-rpm-build
```

这个容器故意基于 Debian：它提供 `rpmbuild`、`rpm2cpio` 和 `x86_64-linux-gnu-gcc`，避免在宿主机安装 RPM 工具链。入口脚本会把挂载源码复制到容器临时目录，以非 root 的 `builder` 用户运行 `scripts/build-rpm.sh`，并只把 `dist/` 复制回挂载工作区。它只是组装检查，不能作为发布证据。

生成的 rpm 只应在一次性 ARM64 RPM VM 或测试主机中安装运行：

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl enable --now abb-box64.service
sudo abb-cli -s
```
