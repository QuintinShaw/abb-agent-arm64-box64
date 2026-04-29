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

## SELinux 检查

```bash
getenforce
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -u abb-box64.service -n 200 --no-pager
```

SELinux enforcing 结果应与 permissive-mode 结果分开记录。
