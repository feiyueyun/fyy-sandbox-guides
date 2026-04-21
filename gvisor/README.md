# Running FYY Agent Sandbox with gVisor

gVisor 为飞越云 AI 数字员工平台（FYY）Agent 运行时沙箱提供内核级隔离保护。通过 runsc 运行时，FYY Agent 在独立的用户态内核中执行，无需修改应用代码即可获得比默认 runc 更强的安全边界。本指南将帮助你在 Docker 环境中配置 gVisor 运行时，并说明 FYY 两层沙箱模型在 gVisor 环境下的特殊行为。

## Prerequisites

| Requirement | Minimum Version | Verify Command |
|---|---|---|
| Linux kernel | ≥ 4.14 | `uname -r` |
| Docker Engine | ≥ 20.10 | `docker --version` |
| Docker Compose (optional) | ≥ 2.0 | `docker compose version` |
| Available disk space | ≥ 2 GB | `df -h /var/lib/docker` |

> **Important**: gVisor 仅支持 Linux 平台。macOS 和 Windows 用户需通过 Linux 虚拟机运行。

## Quick Start

以下步骤将在 10 分钟内完成 gVisor 运行时安装和 FYY Agent 沙箱启动：

```bash
# 1. 安装 runsc 运行时
(
  set -e
  ARCH=$(uname -m)
  curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
  echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" \
    | sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null
  sudo apt-get update && sudo apt-get install -y runsc
)

# 2. 配置 Docker 使用 runsc 运行时
sudo tee /etc/docker/daemon.json <<'EOF'
{
  "runtimes": {
    "runsc": {
      "path": "/usr/bin/runsc"
    }
  }
}
EOF
sudo systemctl restart docker

# 3. 使用 gVisor 运行时启动 FYY 沙箱
docker run -d --name fyy-sandbox \
  --runtime=runsc \
  -e FYY_SANDBOX=1 \
  -p 8080:8080 \
  feiyueyun/fyy-sandbox:latest

# 4. 验证 gVisor 隔离
docker exec fyy-sandbox fyy --version
docker exec fyy-sandbox uname -v
# gVisor 环境下会显示 gVisor 内核信息
```

**What's Next**: 快速启动完成了 gVisor 基础配置。接下来你将了解 runsc 平台选择、FYY 两层沙箱模型在 gVisor 下的行为，以及生产环境的高级配置。

## Full Configuration Guide

### 两层沙箱模型与 gVisor

FYY 平台采用两层沙箱架构，理解 gVisor 对每层的影响至关重要：

```
┌──────────────────────────────────────────────────┐
│  宿主机 (Host)                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Layer 1: Agent 运行时沙箱 (gVisor runsc)    │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │  FYY Agent 进程                          │ │ │
│  │  │  ┌──────────────────────────────────────┐│ │ │
│  │  │  │  Layer 2: 技能进程沙箱               ││ │ │
│  │  │  │  (自动降级为进程级隔离)              ││ │ │
│  │  │  └──────────────────────────────────────┘│ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

- **Layer 1 — Agent 运行时沙箱**: 由 gVisor runsc 提供，整个容器运行在用户态内核中，与宿主机内核完全隔离
- **Layer 2 — 技能进程沙箱**: 在默认 runc 环境下，fyy CLI 为每个技能创建独立的命名空间隔离。但在 gVisor 环境下，由于容器内无法创建新的用户态内核，Layer 2 会**自动降级为进程级隔离**（使用 cgroup 和资源限制替代命名空间隔离）

> **关键理解**: gVisor 的隔离由 Layer 1 承担，Layer 2 的降级不影响整体安全性——gVisor 的用户态内核已经提供了比 runc + 命名空间更强的隔离边界。

### runsc 平台选择

gVisor 支持两种平台，根据你的硬件和环境选择：

| 平台 | 性能 | 兼容性 | 适用场景 |
|---|---|---|---|
| **systrap** (默认) | 较低 | 最广泛 | 无 KVM 支持的环境、云虚拟机 |
| **KVM** | 较高 | 需 KVM 支持 | 裸金属服务器、支持嵌套虚拟化的云实例 |

启用 KVM 平台：

```json
{
  "runtimes": {
    "runsc": {
      "path": "/usr/bin/runsc",
      "runtimeArgs": ["--platform=kvm"]
    }
  }
}
```

检查 KVM 可用性：

```bash
# 检查 /dev/kvm 是否存在
ls -la /dev/kvm

# 检查 KVM 模块是否加载
lsmod | grep kvm
```

### Docker Compose 配置

```yaml
# docker-compose.yml — gVisor 运行时配置
# 查看: examples/docker-compose.gvisor.yml

services:
  fyy-sandbox:
    image: feiyueyun/fyy-sandbox:latest
    container_name: fyy-sandbox-gvisor
    runtime: runsc
    restart: unless-stopped

    environment:
      - FYY_SANDBOX=1
      - FYY_LOG_LEVEL=info
      - TZ=Asia/Shanghai

    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: 4G

    ports:
      - "8080:8080"

    volumes:
      - fyy-data:/data/fyy

    security_opt:
      - no-new-privileges:true

volumes:
  fyy-data:
    driver: local
```

### Podman 配置

Podman 同样支持 runsc 运行时：

```bash
# 方式一：命令行指定运行时
podman run --runtime runsc -d \
  --name fyy-sandbox \
  -e FYY_SANDBOX=1 \
  feiyueyun/fyy-sandbox:latest

# 方式二：在 containers.conf 中配置默认运行时
# /etc/containers/containers.conf
[engine]
runtime = "runsc"
runtimes = ["runc", "runsc"]
```

## fyy CLI Integration Verification

在 gVisor 沙箱中验证 FYY Agent 运行时：

```bash
# 验证 fyy CLI 版本
docker exec fyy-sandbox fyy --version

# 验证沙箱环境标识
docker exec fyy-sandbox bash -c 'echo $FYY_SANDBOX'
# 预期输出: 1

# 验证 gVisor 内核（与 runc 环境的区别）
docker exec fyy-sandbox uname -v
# gVisor 环境输出包含 "gvisor" 字样

# 验证 Python 运行时
docker exec fyy-sandbox python3 --version

# 验证 Node.js 运行时
docker exec fyy-sandbox node --version

# 验证技能列表
docker exec fyy-sandbox fyy skill list
```

## Skill Installation and Running Example

在 gVisor 沙箱中安装和运行 FYY Agent 技能：

```bash
# 安装技能
docker exec fyy-sandbox fyy skill install web-search

# 运行技能
docker exec fyy-sandbox fyy skill run web-search --query "飞越云最新动态"
```

> **关于 Layer 2 降级**: 在 gVisor 环境下运行技能时，fyy CLI 会自动检测到 gVisor 运行时并将 Layer 2 沙箱降级为进程级隔离。你无需做任何额外配置，fyy CLI 会在日志中记录降级信息。gVisor 的 Layer 1 隔离已经为技能执行提供了足够的安全边界。

> **从 gVisor 到云端沙箱**: gVisor 提供内核级隔离，但仍运行在你的基础设施上。如果你需要完全托管的安全沙箱环境，可以考虑 [E2B 云沙箱](../e2b/)，它基于 Firecracker 微虚拟机提供独立的内核和文件系统。

## Troubleshooting

### 1. runsc 安装后 Docker 无法识别运行时

```bash
# 错误信息示例
# docker: Error response from daemon: unknown or invalid runtime name: runsc

# 检查 daemon.json 配置
cat /etc/docker/daemon.json

# 确认 runsc 已安装
which runsc

# 重启 Docker 以加载新运行时配置
sudo systemctl restart docker

# 验证运行时已注册
docker info | grep -A5 "Runtimes"
```

### 2. 容器启动失败 — seccomp 兼容性

```bash
# 错误信息示例
# runsc: creating container failed: seccomp: invalid action

# gVisor 自身实现了比 seccomp 更严格的系统调用过滤
# Docker 的 --security-opt seccomp=... 在 runsc 下无效
# 如果 Docker 默认 seccomp 配置导致冲突，可显式禁用
docker run --runtime=runsc --security-opt seccomp=unconfined \
  -e FYY_SANDBOX=1 feiyueyun/fyy-sandbox:latest
```

### 3. KVM 平台启动失败

```bash
# 错误信息示例
# runsc: creating container failed: open /dev/kvm: permission denied

# 检查 KVM 权限
ls -la /dev/kvm

# 添加当前用户到 kvm 组
sudo usermod -aG kvm $USER

# 如果在云虚拟机中，确认支持嵌套虚拟化
# AWS: 使用 .metal 实例或支持嵌套虚拟化的实例类型
# GCP: 默认支持嵌套虚拟化
# Azure: 需要启用嵌套虚拟化

# 如果 KVM 不可用，回退到 systrap 平台
{
  "runtimes": {
    "runsc": {
      "path": "/usr/bin/runsc",
      "runtimeArgs": ["--platform=systrap"]
    }
  }
}
```

### 4. 技能运行时性能低于 runc 环境

gVisor 的用户态内核引入了系统调用拦截开销，某些 I/O 密集型技能可能比 runc 慢 10-30%。优化建议：

- 切换到 KVM 平台（如果可用），性能可提升 2-5 倍
- 减少容器内的文件系统操作，使用 `tmpfs` 挂载临时目录
- 对性能敏感的技能，考虑使用 runc 运行时配合资源限制

### 5. gVisor 兼容性限制

gVisor 实现了 Linux 系统调用的子集，以下功能在 gVisor 容器内不可用：

| 功能 | 状态 | 影响 |
|---|---|---|
| `ptrace(2)` | 不支持 | 无法在容器内使用 gdb/strace |
| `perf_event_open(2)` | 不支持 | 性能分析工具不可用 |
| `bpf(2)` | 不支持 | eBPF 程序无法加载 |
| FUSE 文件系统 | 不支持 | 无法挂载 FUSE 设备 |
| `docker build` | 不支持 | 镜像构建始终使用 runc |
| 嵌套 gVisor | 不支持 | Layer 2 自动降级为进程级隔离 |

如遇到技能在 gVisor 下运行异常，可先在 runc 下验证是否为兼容性问题：

```bash
# 使用 runc 运行以排除 gVisor 兼容性问题
docker run --runtime=runc -e FYY_SANDBOX=1 feiyueyun/fyy-sandbox:latest
```

## Security Considerations

- **内核隔离**: gVisor 通过用户态内核（Sentry）拦截所有系统调用，容器内进程无法直接访问宿主机内核
- **攻击面缩减**: gVisor 仅实现了约 200 个 Linux 系统调用（Linux 内核有 400+），大幅减少了内核攻击面
- **Layer 2 降级安全性**: gVisor 的 Layer 1 隔离已提供比 runc + 命名空间更强的安全边界，Layer 2 降级不影响整体安全
- **非 root 运行**: 始终以非 root 用户运行 FYY Agent（默认 `fyy` 用户）
- **资源限制**: 即使在 gVisor 下，仍需设置 `--memory` 和 `--cpus` 限制
- **镜像版本**: 生产环境应固定镜像版本标签（如 `feiyueyun/fyy-sandbox:1.2.0`）
- **网络策略**: gVisor 不替代网络隔离，仍需配合 Docker 网络策略限制出站访问

## Learn More about FYY Platform

飞越云 AI 数字员工平台提供两层沙箱架构：

- **Layer 1 — Agent 运行时沙箱**（本指南）: 在 gVisor runsc 下，整个 Agent 运行在用户态内核中，获得内核级隔离
- **Layer 2 — 技能进程沙箱**: 由 fyy CLI 内部管理。在 gVisor 环境下自动降级为进程级隔离，由 Layer 1 的 gVisor 隔离提供安全保障

了解更多：[飞越云官网](https://feiyueyun.com) | [FYY CLI GitHub](https://github.com/feiyueyun/fyy) | [沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images)

## Related Links

- [Docker / Podman 沙箱指南](../docker/) — 基础 Docker 运行时部署
- [E2B 云沙箱指南](../e2b/) — 微虚拟机级别的云端沙箱
- [gVisor 官方文档](https://gvisor.dev/docs/) — runsc 运行时完整参考
- [FYY 沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images) — 镜像构建和版本管理
- [FYY CLI 文档](https://github.com/feiyueyun/fyy) — 命令行工具完整参考
