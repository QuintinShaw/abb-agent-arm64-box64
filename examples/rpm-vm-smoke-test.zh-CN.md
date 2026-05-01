# RPM VM Smoke Test 示例

[English](rpm-vm-smoke-test.md) | 中文

只在一次性 ARM64 RPM VM 或备用测试主机中运行。

## 准备

```bash
sudo dnf install -y epel-release
echo HARDLINK=no | sudo tee /etc/sysconfig/kernel
sudo dnf install -y --setopt=install_weak_deps=False \
  git dkms gcc make "kernel-devel-$(uname -r)" elfutils-libelf-devel \
  unzip wget rpm-build cpio tar systemd cmake
git clone https://github.com/QuintinShaw/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
```

通过你偏好的固定版本方式安装 Box64。辅助脚本偏 Debian。RPM 系统存在可信发行版包时，应优先使用发行版包。Fedora 已打包 Box64：

```bash
sudo dnf install -y box64
```

Box64 二进制必须与 VM 发行版的 glibc 兼容。不要把 Ubuntu 上的二进制直接复制到 Rocky/RHEL，除非已确认它不需要比 VM 更新的 glibc。Fedora RPM 也可能要求比 Rocky/RHEL 9 更新的 glibc。

如果目标 RPM 发行版没有可信兼容的 Box64 包，不要在无 KVM 的慢速 VM 里编译它。请使用物理 ARM64 主机、带 KVM 的 ARM64 VM，或 EL9 兼容的 ARM64 构建环境，然后只把生成的 Box64 二进制复制进一次性 VM 做包验证。

还需要确认 Box64 能找到 x86_64 `libstdc++.so.6` 和 `libgcc_s.so.1`。在 Rocky/RHEL 9 上，应从可信 Box64 包或匹配的 Rocky/RHEL x86_64 运行库 RPM 获取，并放入 Box64 搜索路径，例如 `/usr/lib/box64-x86_64-linux-gnu`。

## 构建

```bash
./scripts/build-rpm.sh
```

生成的 rpm 只供本地使用：

```text
dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
```

## 安装

```bash
sudo dnf install ./dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
sudo systemctl enable --now abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

官方 RPM 内容将 `abb-cli` 放在 `/bin/abb-cli`；本构建器会把它重新放入本地 ABB 文件树，使封装脚本可以通过 Box64 运行它。

也可以运行仓库内验证脚本：

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --enable-service
```

第一条命令只读。安装命令会检查 rpm 元数据，通过 `dnf` 或 `yum` 安装包，检查 DKMS 状态、内核模块、systemd 状态，并收集最近 journal 和 SELinux 拒绝记录。它不会把主机注册到 NAS，也不会启动备份。

成功的服务 smoke test 应在 service journal 中看到 `ABB backup service starts`，随后看到 kernel driver 检查。该包会创建 `/opt/synosnap`，供 ABB 保存 snapshot history 数据库；如果该目录缺失，服务可能在日志中输出 `SnapshotHistoryDB: Failed to open database` 后退出。

## SELinux 检查

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

SELinux enforcing 结果应与 permissive-mode 结果分开记录。

## 卸载检查

完成服务和 DKMS 检查后，在一次性 VM 中验证包移除：

```bash
./scripts/verify-rpm-vm.sh --uninstall
```

不要把卸载输出当作 NAS 端任务或备份数据已删除的证明。那些不属于本地 RPM 包范围。
