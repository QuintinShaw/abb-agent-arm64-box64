# 架构

[English](architecture.md) | 中文

`abb-agent-arm64-box64` 打包了一套本地兼容层，用于在 ARM64 上运行 Synology Active Backup for Business Linux x86_64 Agent。

## 组件

- ARM64 Linux kernel
- ARM64 原生 `synosnap` DKMS 内核模块
- Box64 x86_64 用户态模拟器
- 从官方包中本地提取的 Synology ABB x86_64 用户态文件
- 社区维护的 wrapper 脚本和 systemd unit
- 社区维护的挂载点枚举兼容 shim

## 数据路径

```text
ABB x86_64 userspace
  -> Box64
  -> x86_64 libsynosnap.so
  -> Linux syscall/ioctl boundary
  -> ARM64 native synosnap kernel module
  -> /dev/synosnap*
```

PoC 的关键结果是：Box64 下的 x86_64 ABB 用户态发出的私有 snapshot ioctl 可以抵达 ARM64 原生 `synosnap` 内核模块。

## 为什么使用 Box64

PoC 发现 Box64 在该工作负载上明显优于 QEMU。Box64 可以运行 ABB 工具，并打通 `sbdctl` 和 ABB daemon 所需的私有 ioctl 路径。

QEMU 不是本项目的主路线。

## Mount Enumeration Shim

在已测试的 ARM64 主机上，Box64 下的 x86_64 `libmount.so.1` 能打开并读取 `/proc/self/mountinfo`，但生成的 mount table 为空。结果是 ABB 向 NAS 返回空自定义卷列表。

包会构建并安装一个 x86_64 preload shim：

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

wrapper 会在该文件存在时用 `BOX64_LD_PRELOAD` 加载它。它只实现 PoC 中 ABB 挂载枚举用到的 libmount 符号子集。

这是兼容性 workaround，不是通用 libmount 替代品。
