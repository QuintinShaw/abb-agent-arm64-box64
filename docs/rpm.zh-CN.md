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

RHEL-like 系统通常需要 EPEL，或另一个可信 DKMS 仓库，才能安装该包。请安装当前运行内核对应的 headers，而不是只安装仓库里的最新内核 headers：

```bash
sudo dnf install -y epel-release
echo HARDLINK=no | sudo tee /etc/sysconfig/kernel
sudo dnf install -y --setopt=install_weak_deps=False \
  dkms gcc make "kernel-devel-$(uname -r)" elfutils-libelf-devel
```

Box64 必须用与目标发行版兼容的方式安装。存在可信发行版包时，应优先使用发行版包。Fedora 已打包 Box64，因此 Fedora 测试 VM 可以走发行版包路线：

```bash
sudo dnf install -y box64
```

不要直接从其他发行版复制 Box64 二进制，除非已确认 glibc 兼容性。例如，在 Ubuntu 22.04 上构建的 Box64 可能需要 `GLIBC_2.35`，在只提供 glibc 2.34 的 Rocky/RHEL 9 上会失败。Fedora RPM 也可能要求比 Rocky/RHEL 9 更新的 glibc。

如果目标 RPM 发行版没有可信兼容的 Box64 包，不要在无 KVM 的慢速 VM 里耗时编译 Box64。请使用物理 ARM64 主机、带 KVM 的 ARM64 VM，或 EL9 兼容的 ARM64 构建环境，然后只把本地构建出的 Box64 二进制复制进一次性 VM 做包验证。

Box64 还必须能找到官方 ABB 二进制需要的 x86_64 GNU 运行库。在 Rocky/RHEL 9 上，如果缺少这些 x86_64 库，服务启动可能会失败并提示
`Error loading needed lib libstdc++.so.6` 或 `libgcc_s.so.1`。应通过可信 Box64/发行版机制安装它们；仅用于一次性验证时，也可以把 Rocky x86_64 包解包到 Box64 库路径，例如 `/usr/lib/box64-x86_64-linux-gnu`。

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl start abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

服务不会自动启用。
官方 RPM payload 可能不包含 `/opt/Synology/ActiveBackupforBusiness/bin/abb-cli`，因此 `abb-cli` 缺失时请使用 systemd 和 journal 检查。

该包会创建 `/opt/synosnap`，供 ABB 保存 snapshot history 数据库。如果该目录缺失，`synology-backupd` 可能先启动然后退出，并在日志中显示：

```text
SnapshotHistoryDB: Failed to open database at '/opt/synosnap/snapshot-history-db.sqlite'
```

仓库也包含 VM 侧验证脚本：

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --install --start-service --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --uninstall
```

默认模式只读。安装和卸载模式必须显式指定，因为它们会改变系统包、DKMS 状态和 systemd 状态。该验证脚本不会注册 NAS、创建任务或执行备份/恢复测试。

卸载应移除 RPM、DKMS 条目、已加载的 `synosnap` 模块，以及 `/usr/lib/synosnap` 等包拥有的 helper 路径。`/opt/Synology/ActiveBackupforBusiness` 和 `/opt/synosnap` 下的运行数据可能保留；应按测试计划先保留或手动删除。

在没有 KVM 的慢速模拟 VM 中，DKMS 可能耗时很长，因为 Synology 的 `synosnap` 构建会先执行大量内核 API feature probe，然后才编译最终模块，而且 DKMS 可能对每个已安装内核触发 `dracut --regenerate-all`。TCG-only QEMU 不适合做这类验证。RPM 安装验证更建议使用物理 ARM64 主机或带 KVM 的 ARM64 VM。

## SELinux

SELinux enforcing 时，在服务启动、NAS 注册、备份和恢复期间收集 denial：

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

不要在理解被拒绝的路径和操作前添加宽泛 allow policy。SELinux 发现应记录在测试报告中。
