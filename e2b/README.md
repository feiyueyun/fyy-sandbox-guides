# Running FYY Agent Sandbox with E2B

E2B 为飞越云 AI 数字员工平台（FYY）Agent 运行时沙箱提供完全托管的云端隔离环境。基于 Firecracker 微虚拟机技术，每个 FYY Agent 沙箱运行在独立的轻量级虚拟机中，拥有自己的内核和文件系统，提供比容器更强的安全边界。本指南将帮助你在 E2B 云平台上构建和部署 FYY Agent 自定义沙箱模板，无需管理底层基础设施。

## Prerequisites

| Requirement | Minimum Version | Verify Command |
|---|---|---|
| E2B CLI | ≥ 0.16 | `e2b --version` |
| Docker Engine | ≥ 20.10 | `docker --version` |
| E2B API Key | — | `echo $E2B_API_KEY` |
| Node.js (for SDK) | ≥ 18 | `node --version` |
| Python (for SDK) | ≥ 3.9 | `python3 --version` |

> **Note**: E2B 沙箱运行在 E2B 云平台上，无需本地 Linux 环境或 KVM 支持。

### 安装 E2B CLI

```bash
# 使用 npm 安装
npm install -g @e2b/cli

# 验证安装
e2b --version

# 配置 API Key
export E2B_API_KEY="your-api-key"
# 或添加到 shell 配置文件
echo 'export E2B_API_KEY="your-api-key"' >> ~/.bashrc
```

获取 API Key：访问 [e2b.dev](https://e2b.dev) 注册账号并在 Dashboard 中创建。

## Quick Start

以下步骤将在 10 分钟内完成 FYY Agent 沙箱在 E2B 平台上的构建和部署：

```bash
# 1. 创建沙箱模板目录
mkdir fyy-e2b-sandbox && cd fyy-e2b-sandbox

# 2. 创建 e2b.Dockerfile
cat > e2b.Dockerfile <<'EOF'
FROM feiyueyun/fyy-sandbox:latest
EOF

# 3. 创建 e2b.toml 配置
cat > e2b.toml <<'EOF'
[template]
name = "fyy-sandbox"
dockerfile = "e2b.Dockerfile"

[template.env]
FYY_SANDBOX = "1"
EOF

# 4. 构建并部署沙箱模板
e2b template build

# 5. 使用模板创建沙箱
e2b sandbox create fyy-sandbox
```

**What's Next**: 快速启动完成了 E2B 沙箱的基础部署。接下来你将了解完整的 e2b.toml 配置选项、SDK 集成方式，以及生产环境的最佳实践。

## Full Configuration Guide

### e2b.Dockerfile — 自定义沙箱镜像

E2B 使用 `e2b.Dockerfile`（注意文件名前缀）定义沙箱镜像。基于 `feiyueyun/fyy-sandbox` 构建自定义模板：

```dockerfile
# e2b.Dockerfile — FYY Agent E2B 沙箱模板
# 查看: examples/e2b.Dockerfile

# 基于 FYY 沙箱官方镜像
FROM feiyueyun/fyy-sandbox:latest

# 安装额外系统依赖（可选）
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 安装额外 Python 包（可选）
RUN pip install --no-cache-dir pandas numpy

# 预装自定义技能（可选）
COPY --chown=fyy:fyy ./skills/ /data/fyy/skills/

# E2B 要求以 root 用户结束 Dockerfile
# 沙箱启动后由 E2B 运行时管理用户权限
USER root
```

> **Important**: E2B 的 `e2b.Dockerfile` 与标准 Dockerfile 的区别：
> - 文件名必须为 `e2b.Dockerfile`
> - Dockerfile 结尾必须是 `USER root`
> - 不支持 `VOLUME`、`EXPOSE`、`HEALTHCHECK` 指令（由 E2B 运行时管理）
> - 构建上下文大小限制为 100 MB

### e2b.toml — 沙箱模板配置

`e2b.toml` 定义沙箱模板的元数据和运行时配置：

```toml
# e2b.toml — FYY Agent E2B 沙箱模板配置
# 查看: examples/e2b.toml

# ---------------------------------------------------------------------------
# 模板基本信息
# ---------------------------------------------------------------------------
[template]
# 模板名称 — 用于 SDK 中引用
name = "fyy-sandbox"
# Dockerfile 路径
dockerfile = "e2b.Dockerfile"

# ---------------------------------------------------------------------------
# 环境变量
# ---------------------------------------------------------------------------
[template.env]
# 沙箱标识 — fyy CLI 检测此变量以确定运行环境
FYY_SANDBOX = "1"
# 日志级别
FYY_LOG_LEVEL = "info"

# ---------------------------------------------------------------------------
# 资源配置
# ---------------------------------------------------------------------------
# CPU 核心数 (1-8)
cpu_count = 2
# 内存大小 (MB, 512-16384)
memory_mb = 4096

# ---------------------------------------------------------------------------
# 超时设置
# ---------------------------------------------------------------------------
# 沙箱最大运行时间 (秒, 默认 300, 最大 3600)
timeout = 600
```

### 构建和部署模板

```bash
# 构建沙箱模板（首次构建需要 2-5 分钟）
e2b template build

# 查看已构建的模板
e2b template list

# 更新模板（修改 Dockerfile 或 toml 后重新构建）
e2b template build --force
```

### SDK 集成

E2B 提供 Python 和 Node.js SDK 用于程序化创建和管理沙箱：

**Python SDK:**

```python
from e2b import Sandbox

# 创建 FYY Agent 沙箱
sandbox = Sandbox(template="fyy-sandbox")

# 验证 fyy CLI
result = sandbox.process.run("fyy --version")
print(result.stdout)

# 运行 Agent 技能
result = sandbox.process.run("fyy skill run hello-world")
print(result.stdout)

# 关闭沙箱
sandbox.close()
```

**Node.js SDK:**

```typescript
import { Sandbox } from "@e2b/code-interpreter";

// 创建 FYY Agent 沙箱
const sandbox = await Sandbox.create({ template: "fyy-sandbox" });

// 验证 fyy CLI
const result = await sandbox.process.start("fyy --version");
console.log(result.stdout);

// 关闭沙箱
await sandbox.close();
```

### 资源配置参考

| 场景 | CPU | Memory | Timeout | 适用 |
|---|---|---|---|---|
| 轻量技能 | 1 核 | 512 MB | 300s | 简单查询、文本处理 |
| 标准部署 | 2 核 | 4 GB | 600s | 通用 Agent 任务 |
| 高性能 | 4 核 | 8 GB | 1200s | 数据处理、代码生成 |
| 最大配置 | 8 核 | 16 GB | 3600s | 复杂计算、多技能并发 |

## fyy CLI Integration Verification

在 E2B 沙箱中验证 FYY Agent 运行时：

```bash
# 使用 E2B CLI 创建沙箱
e2b sandbox create fyy-sandbox

# 或使用 SDK
# Python:
python3 -c "
from e2b import Sandbox
sb = Sandbox(template='fyy-sandbox')
print(sb.process.run('fyy --version').stdout)
print(sb.process.run('echo \$FYY_SANDBOX').stdout)
print(sb.process.run('python3 --version').stdout)
print(sb.process.run('node --version').stdout)
sb.close()
"
```

验证检查项：

| 检查项 | 命令 | 预期输出 |
|---|---|---|
| fyy CLI 版本 | `fyy --version` | `fyy x.y.z` |
| 沙箱环境标识 | `echo $FYY_SANDBOX` | `1` |
| Python 运行时 | `python3 --version` | `Python 3.x.x` |
| Node.js 运行时 | `node --version` | `v2x.x.x` |

## Skill Installation and Running Example

在 E2B 沙箱中安装和运行 FYY Agent 技能：

```bash
# 使用 E2B CLI
e2b sandbox exec fyy-sandbox -- "fyy skill install web-search"
e2b sandbox exec fyy-sandbox -- "fyy skill run web-search --query '飞越云最新动态'"

# 使用 Python SDK
python3 -c "
from e2b import Sandbox
sb = Sandbox(template='fyy-sandbox')
sb.process.run('fyy skill install web-search')
result = sb.process.run('fyy skill run web-search --query \"飞越云最新动态\"')
print(result.stdout)
sb.close()
"
```

> **从 E2B 到自托管沙箱**: E2B 提供完全托管的云端沙箱，适合不想管理基础设施的团队。如果你需要更强的控制力或数据本地化要求，可以参考 [Docker/Podman 指南](../docker/) 进行自托管部署，或使用 [gVisor 指南](../gvisor/) 获得内核级隔离。

## Troubleshooting

### 1. 模板构建失败 — 镜像拉取超时

```bash
# 错误信息示例
# Error: failed to pull base image feiyueyun/fyy-sandbox:latest

# E2B 构建环境可能无法直接访问 Docker Hub
# 解决方案一：使用 E2B 支持的镜像仓库
# 将镜像推送到 E2B 可访问的仓库后引用

# 解决方案二：减小构建上下文
# 确保构建目录中不包含大文件
du -sh .
# E2B 构建上下文限制为 100 MB
```

### 2. 沙箱创建超时

```bash
# 错误信息示例
# Error: sandbox creation timed out after 300s

# 增加超时时间
# 在 e2b.toml 中设置
timeout = 600

# 或在 SDK 中设置
# Python:
sandbox = Sandbox(template="fyy-sandbox", timeout=600)
```

### 3. API Key 无效或过期

```bash
# 错误信息示例
# Error: Invalid API key

# 验证 API Key
echo $E2B_API_KEY

# 重新设置
export E2B_API_KEY="e2b-xxxxx"

# 在 E2B Dashboard 中检查 Key 状态
# https://e2b.dev/dashboard
```

## Security Considerations

- **微虚拟机隔离**: E2B 基于 Firecracker 微虚拟机，每个沙箱拥有独立的内核和文件系统，隔离级别高于容器
- **无宿主机共享**: 沙箱之间不共享内核，一个沙箱的内核漏洞不会影响其他沙箱
- **自动销毁**: 沙箱在超时后自动销毁，不留残留数据
- **网络隔离**: 每个沙箱有独立的网络栈，默认无法访问其他沙箱
- **API Key 安全**: 不要将 API Key 硬编码在代码中，使用环境变量或密钥管理服务
- **数据持久化**: E2B 沙箱默认不持久化数据，如需持久化请使用 E2B 的文件系统 API 或外部存储
- **资源限制**: E2B 自动限制沙箱资源，但仍需在 e2b.toml 中合理配置，避免资源浪费

## Learn More about FYY Platform

飞越云 AI 数字员工平台提供两层沙箱架构：

- **Layer 1 — Agent 运行时沙箱**（本指南）: 在 E2B 平台上，Agent 运行在 Firecracker 微虚拟机中，获得完整的内核级隔离
- **Layer 2 — 技能进程沙箱**: 由 fyy CLI 内部管理。在 E2B 微虚拟机内，Layer 2 正常使用命名空间隔离，无需降级

了解更多：[飞越云官网](https://feiyueyun.com) | [FYY CLI GitHub](https://github.com/feiyueyun/fyy) | [沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images)

## Related Links

- [Docker / Podman 沙箱指南](../docker/) — 基础 Docker 运行时部署
- [gVisor 隔离沙箱指南](../gvisor/) — 内核级隔离的 Agent 运行环境
- [E2B 官方文档](https://e2b.dev/docs) — E2B 平台完整参考
- [Firecracker 微虚拟机](https://firecracker-microvm.github.io/) — E2B 底层技术
- [FYY 沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images) — 镜像构建和版本管理
- [FYY CLI 文档](https://github.com/feiyueyun/fyy) — 命令行工具完整参考
