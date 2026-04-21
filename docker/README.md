# Running FYY Agent Sandbox with Docker / Podman

Docker and Podman 是部署飞越云 AI 数字员工平台（FYY）Agent 运行时沙箱最直接的方式。本指南将帮助你在 5 分钟内完成从镜像拉取到 Agent 技能运行的完整配置，适用于本地开发、CI/CD 管道和生产部署场景。无论你使用 Docker Engine 还是 Podman，均可通过同一套 OCI 镜像 `feiyueyun/fyy-sandbox:latest` 快速启动隔离的 Agent 运行环境。

## Prerequisites

| Requirement | Minimum Version | Verify Command |
|---|---|---|
| Docker Engine or Podman | Docker ≥ 20.10 / Podman ≥ 3.0 | `docker --version` or `podman --version` |
| Docker Compose (optional) | ≥ 2.0 | `docker compose version` |
| Available disk space | ≥ 2 GB | `df -h /var/lib/docker` |
| Network access | Docker Hub / registry | `docker pull hello-world` |

> **Note**: Podman 用户可将本指南中所有 `docker` 命令替换为 `podman`，两者 CLI 完全兼容。

## Quick Start

以下步骤将在 5 分钟内启动一个完整的 FYY Agent 沙箱环境：

```bash
# 1. 拉取 FYY 沙箱镜像
docker pull feiyueyun/fyy-sandbox:latest

# 2. 启动沙箱容器
docker run -d --name fyy-sandbox \
  -e FYY_SANDBOX=1 \
  -p 8080:8080 \
  feiyueyun/fyy-sandbox:latest

# 3. 验证 Agent 运行时
docker exec fyy-sandbox fyy --version

# 4. 运行第一个 Agent 技能
docker exec fyy-sandbox fyy skill run hello-world
```

**What's Next**: 快速启动验证了沙箱的基本运行能力。接下来你将了解完整的配置选项，包括资源限制、持久化存储、多技能部署和生产环境安全加固。

## Full Configuration Guide

### Docker Compose 部署（推荐）

使用 Docker Compose 可以声明式地管理沙箱配置，适合多容器编排和生产部署：

```yaml
# docker-compose.yml — 完整配置示例
# 查看: examples/docker-compose.yml

services:
  fyy-sandbox:
    image: feiyueyun/fyy-sandbox:latest
    container_name: fyy-sandbox
    restart: unless-stopped

    # 资源限制
    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: 4G
        reservations:
          cpus: "0.5"
          memory: 512M

    # 环境变量
    environment:
      - FYY_SANDBOX=1
      - FYY_LOG_LEVEL=info
      - TZ=Asia/Shanghai

    # 端口映射
    ports:
      - "8080:8080"

    # 持久化存储
    volumes:
      - fyy-data:/data/fyy
      - ./skills:/data/fyy/skills:ro

    # 安全加固
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:size=100M
      - /run:size=10M

volumes:
  fyy-data:
    driver: local
```

启动服务：

```bash
docker compose up -d
docker compose logs -f fyy-sandbox
```

### 自定义 Dockerfile

当需要预装额外依赖时，可基于 `feiyueyun/fyy-sandbox` 构建自定义镜像：

```dockerfile
# Dockerfile — 自定义沙箱镜像示例
# 查看: examples/Dockerfile

FROM feiyueyun/fyy-sandbox:latest

# 安装额外系统包
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 安装额外 Python 包
RUN pip install --no-cache-dir pandas numpy

# 预装自定义技能
COPY --chown=fyy:fyy ./my-skills/ /data/fyy/skills/

# 切换回非 root 用户
USER fyy
```

构建并运行：

```bash
docker build -t fyy-sandbox-custom .
docker run -d --name fyy-custom \
  -e FYY_SANDBOX=1 \
  fyy-sandbox-custom
```

### 资源配置参考

| 场景 | CPU | Memory | 磁盘 | 适用 |
|---|---|---|---|---|
| 开发测试 | 1 核 | 1 GB | 10 GB | 本地开发、调试 |
| 标准部署 | 2 核 | 4 GB | 20 GB | 单技能生产部署 |
| 高性能 | 4 核 | 8 GB | 50 GB | 多技能并发、数据处理 |

### 持久化与数据管理

FYY 沙箱的数据目录结构：

```
/data/fyy/
├── skills/        # 技能包目录
├── workspace/     # 工作空间
├── logs/          # 运行日志
└── config/        # 配置文件
```

推荐使用命名卷（named volume）持久化数据：

```bash
# 创建命名卷
docker volume create fyy-data

# 挂载到容器
docker run -d -v fyy-data:/data/fyy feiyueyun/fyy-sandbox:latest
```

## fyy CLI Integration Verification

在沙箱容器内验证 FYY Agent 运行时是否正常工作：

```bash
# 验证 fyy CLI 版本
docker exec fyy-sandbox fyy --version
# 预期输出: fyy x.y.z

# 验证沙箱环境标识
docker exec fyy-sandbox bash -c 'echo $FYY_SANDBOX'
# 预期输出: 1

# 验证 Python 运行时
docker exec fyy-sandbox python3 --version

# 验证 Node.js 运行时
docker exec fyy-sandbox node --version

# 验证技能列表
docker exec fyy-sandbox fyy skill list
```

## Skill Installation and Running Example

FYY Agent 技能是完成特定任务的独立模块。在沙箱中安装和运行技能：

```bash
# 从技能市场安装技能
docker exec fyy-sandbox fyy skill install web-search

# 查看已安装技能
docker exec fyy-sandbox fyy skill list

# 运行技能
docker exec fyy-sandbox fyy skill run web-search --query "飞越云最新动态"

# 通过挂载目录批量安装技能
docker run -d --name fyy-sandbox \
  -v ./my-skills:/data/fyy/skills:ro \
  -e FYY_SANDBOX=1 \
  feiyueyun/fyy-sandbox:latest
```

> **从 Docker 到更强隔离**: Docker 的默认 runc 运行时提供进程级隔离。如果你的 Agent 需要运行不受信任的代码或处理敏感数据，可以结合 [gVisor 运行时](../gvisor/) 实现内核级隔离，或使用 [E2B 云沙箱](../e2b/) 获得微虚拟机级别的安全边界。

## Troubleshooting

### 1. 镜像拉取失败或超时

```bash
# 错误信息示例
# Error response from daemon: Get "https://registry-1.docker.io/v2/": net/http: TLS handshake timeout

# 解决方案：配置镜像加速器
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": ["https://your-mirror.example.com"]
}

# 重启 Docker
sudo systemctl restart docker
```

### 2. 容器启动后立即退出

```bash
# 查看退出日志
docker logs fyy-sandbox

# 常见原因：内存不足
# 增加内存限制
docker run -d --memory=4g feiyueyun/fyy-sandbox:latest

# 常见原因：端口冲突
# 更换端口映射
docker run -d -p 9090:8080 feiyueyun/fyy-sandbox:latest
```

### 3. 技能运行时权限错误

```bash
# 错误信息示例
# Permission denied: /data/fyy/skills/

# 解决方案：确保数据目录权限正确
docker exec -u root fyy-sandbox chown -R fyy:fyy /data/fyy

# 或在启动时指定用户
docker run -d --user fyy feiyueyun/fyy-sandbox:latest
```

## Security Considerations

- **非 root 运行**: 默认以 `fyy` 用户（UID 1000）运行，不要使用 `--privileged` 标志
- **只读文件系统**: 生产环境建议启用 `read_only: true`，配合 `tmpfs` 挂载临时目录
- **资源限制**: 始终设置 `--memory` 和 `--cpus` 限制，防止失控技能消耗宿主机资源
- **网络隔离**: 使用 Docker 网络策略限制沙箱的外部访问范围
- **镜像版本**: 生产环境应固定镜像版本标签（如 `feiyueyun/fyy-sandbox:1.2.0`），避免使用 `latest`
- **安全选项**: 启用 `no-new-privileges:true` 防止提权攻击
- **密钥管理**: 不要在环境变量或配置文件中硬编码 API 密钥，使用 Docker secrets 或外部密钥管理服务

## Learn More about FYY Platform

飞越云 AI 数字员工平台提供两层沙箱架构：

- **Layer 1 — Agent 运行时沙箱**（本指南）: 为 AI Agent 提供隔离的运行环境，包含完整的文件系统、运行时和技能执行框架
- **Layer 2 — 技能进程沙箱**: 由 fyy CLI 内部管理，为每个技能的子进程提供进程级隔离，防止技能间相互干扰

了解更多：[飞越云官网](https://feiyueyun.com) | [FYY CLI GitHub](https://github.com/feiyueyun/fyy) | [沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images)

## Related Links

- [gVisor 隔离沙箱指南](../gvisor/) — 内核级隔离的 Agent 运行环境
- [E2B 云沙箱指南](../e2b/) — 微虚拟机级别的云端沙箱
- [FYY 沙箱镜像仓库](https://github.com/feiyueyun/fyy-sandbox-images) — 镜像构建和版本管理
- [FYY CLI 文档](https://github.com/feiyueyun/fyy) — 命令行工具完整参考
- [Docker 官方文档](https://docs.docker.com/)
- [Podman 官方文档](https://podman.io/docs)
