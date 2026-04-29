# RPM 构建与验证

[English](rpm.md) | 中文

RPM 支持仍是实验功能，必须在一次性 RPM VM 或备用 ARM64 主机中验证。脚本使用 Synology 官方 x86_64 rpm zip 作为本地输入，提取官方 rpm payload，并构建本地测试用 aarch64 wrapper rpm。

## 构建依赖

安装对应发行版软件包：

```bash
sudo dnf install -y git dkms gcc make kernel-devel unzip wget rpm-build rpmdevtools cpio tar
sudo dnf install -y gcc-x86_64-linux-gnu || true
```

部分 RPM 发行版不提供 `x86_64-linux-gnu-gcc`。这种情况下需要从发行版安装交叉编译器，或在专用 toolchain 容器中构建兼容 shim。

## 构建

默认构建会下载并校验 Synology 官方 rpm zip：

```bash
./scripts/build-rpm.sh
```

手动官方 zip：

```bash
ABB_OFFICIAL_RPM_ZIP=/path/to/official-rpm.zip \
ABB_OFFICIAL_RPM_SHA256=<sha256> \
./scripts/build-rpm.sh
```

预期输出：

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

不要上传生成的 rpm。它包含从官方包中提取的 Synology 专有文件。

## 容器组装检查

可以在不触碰宿主机 RPM 数据库的情况下检查包组装。提供的容器基于 Debian，因为它的标准包里有需要的 RPM 构建工具和 x86_64 交叉编译器：

```bash
podman build -f docker/Containerfile.rpm-build -t abb-rpm-build .
podman run --rm -v "$PWD:/work:Z" abb-rpm-build
```

容器会把挂载的源码复制到临时目录，以非 root 用户执行 RPM 构建，并只把 `dist/` 复制回挂载工作区。这不会验证 DKMS、systemd、SELinux、NAS 注册、备份或恢复行为。

## 在一次性 VM 中安装

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo abb-cli -s
```

服务不会自动启用。

仓库也包含 VM 侧验证脚本：

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --start-service
./scripts/verify-rpm-vm.sh --uninstall
```

默认模式只读。安装和卸载模式必须显式指定，因为它们会改变系统包、DKMS 状态和 systemd 状态。该验证脚本不会注册 NAS、创建任务或执行备份/恢复测试。

## SELinux

SELinux enforcing 时，在服务启动、NAS 注册、备份和恢复期间收集 denial：

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

不要在理解被拒绝的路径和操作前添加宽泛 allow policy。SELinux 发现应记录在测试报告中。
