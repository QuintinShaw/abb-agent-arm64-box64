# 容器说明

[English](README.md) | 中文

容器适合做包组装检查，但不能替代 VM 或真实主机验证。`synosnap` 是内核模块，备份行为依赖真实块设备、systemd、NAS 连接和恢复测试。

容器适合：

- 验证脚本能解析并提取官方包。
- 检查 rpm/deb 包元数据。
- 执行 shell 语法检查。
- 在隔离容器内以非 root 用户执行包组装。

一次性 VM 或备用物理主机适合：

- DKMS 构建、加载和卸载。
- systemd daemon 生命周期。
- SELinux/AppArmor。
- NAS 注册。
- 备份中断、重启和恢复校验和测试。

容器内 RPM 组装检查见 [Containerfile.rpm-build](Containerfile.rpm-build) 和 [../examples/container-rpm-build.zh-CN.md](../examples/container-rpm-build.zh-CN.md)。镜像入口会把挂载的源码复制到容器临时目录，以非 root 的 `builder` 用户运行 `scripts/build-rpm.sh`，最后只把 `dist/` 复制回挂载工作区。
