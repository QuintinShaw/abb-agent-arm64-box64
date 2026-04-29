# 容器说明

[English](README.md) | 中文

容器适合做包组装检查，但不足以做生产验证。`synosnap` 是内核模块，备份行为依赖真实块设备、systemd、NAS 连接和恢复测试。

容器适合：

- 验证脚本能解析并提取官方包。
- 检查 rpm/deb 包元数据。
- 执行 shell 语法检查。

一次性 VM 或备用物理主机适合：

- DKMS 构建、加载和卸载。
- systemd daemon 生命周期。
- SELinux/AppArmor。
- NAS 注册。
- 备份中断、重启和恢复 hash 测试。

容器内 RPM 组装检查见 [Containerfile.rpm-build](Containerfile.rpm-build) 和 [../examples/container-rpm-build.zh-CN.md](../examples/container-rpm-build.zh-CN.md)。
