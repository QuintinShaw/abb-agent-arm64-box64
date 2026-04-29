# RPM VM Smoke Test 示例

[English](rpm-vm-smoke-test.md) | 中文

只在一次性 ARM64 RPM VM 或备用测试主机中运行。

## 准备

```bash
sudo dnf install -y git dkms gcc make kernel-devel unzip wget rpm-build cpio tar systemd
git clone https://github.com/QuintinShaw/abb-agent-arm64-box64.git
cd abb-agent-arm64-box64
```

通过你偏好的固定版本方式安装 Box64。辅助脚本偏 Debian；在 RPM 系统上更建议使用审计过的本地包或固定版本手动构建。

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
sudo systemctl start abb-box64.service
sudo systemctl status abb-box64.service --no-pager
sudo abb-cli -s
```

也可以运行仓库内验证脚本：

```bash
./scripts/verify-rpm-vm.sh
./scripts/verify-rpm-vm.sh --install --rpm dist/abb-agent-arm64-box64-3.2.0-5053.aarch64.rpm
./scripts/verify-rpm-vm.sh --start-service
```

第一条命令只读。安装命令会检查 rpm 元数据，通过 `dnf` 或 `yum` 安装包，检查 DKMS 状态、内核模块、systemd 状态，并收集最近 journal 和 SELinux denial。它不会把主机注册到 NAS，也不会启动备份。

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
