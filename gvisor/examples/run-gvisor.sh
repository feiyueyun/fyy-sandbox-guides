#!/usr/bin/env bash
# run-gvisor.sh — FYY Agent Sandbox gVisor 运行时一键配置脚本
#
# 使用方法:
#   sudo ./run-gvisor.sh              # 安装 runsc 并启动沙箱
#   ./run-gvisor.sh --skip-install    # 跳过安装，仅启动沙箱
#
# 功能:
#   - 检测并安装 gVisor runsc 运行时
#   - 配置 Docker daemon 以支持 runsc
#   - 使用 gVisor 运行时启动 FYY Agent 沙箱
#   - 验证 gVisor 隔离是否生效

set -euo pipefail

# ---------------------------------------------------------------------------
# 配置
# ---------------------------------------------------------------------------
IMAGE_NAME="feiyueyun/fyy-sandbox"
IMAGE_TAG="${FYY_SANDBOX_TAG:-latest}"
CONTAINER_NAME="fyy-sandbox-gvisor"
HOST_PORT="${FYY_PORT:-8080}"
CONTAINER_PORT="8080"
RUNSC_PLATFORM="${FYY_GVISOR_PLATFORM:-systrap}"
SKIP_INSTALL=false

# 解析参数
for arg in "$@"; do
    case "${arg}" in
        --skip-install) SKIP_INSTALL=true ;;
    esac
done

# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
# 检查是否为 Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    error "gVisor 仅支持 Linux 平台。当前系统: $(uname -s)"
fi

# 检查 Docker
if ! command -v docker &>/dev/null; then
    error "Docker 未安装。请访问 https://docs.docker.com/get-docker/ 安装 Docker。"
fi

# 检查 root 权限（安装 runsc 需要）
if [[ "${SKIP_INSTALL}" == "false" ]] && [[ "${EUID}" -ne 0 ]]; then
    error "安装 runsc 需要 root 权限。请使用 sudo 运行，或添加 --skip-install 跳过安装。"
fi

# ---------------------------------------------------------------------------
# 安装 runsc
# ---------------------------------------------------------------------------
if [[ "${SKIP_INSTALL}" == "false" ]]; then
    if command -v runsc &>/dev/null; then
        info "runsc 已安装: $(runsc --version 2>&1 || echo 'unknown')"
    else
        info "安装 gVisor runsc..."

        # 添加 gVisor APT 仓库
        ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
        curl -fsSL https://gvisor.dev/archive.key \
            | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg

        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" \
            | tee /etc/apt/sources.list.d/gvisor.list > /dev/null

        apt-get update && apt-get install -y runsc

        info "runsc 安装完成: $(runsc --version 2>&1 || echo 'unknown')"
    fi
else
    info "跳过 runsc 安装"
    if ! command -v runsc &>/dev/null; then
        error "runsc 未安装且跳过了安装步骤。请先安装 runsc 或移除 --skip-install 参数。"
    fi
fi

# ---------------------------------------------------------------------------
# 配置 Docker daemon
# ---------------------------------------------------------------------------
info "配置 Docker daemon 以支持 runsc 运行时..."

DAEMON_JSON="/etc/docker/daemon.json"

# 读取现有配置或创建新配置
if [[ -f "${DAEMON_JSON}" ]]; then
    info "检测到现有 daemon.json，将合并 runsc 配置"
    # 使用 python3 合并 JSON（保留现有配置）
    python3 -c "
import json, sys
with open('${DAEMON_JSON}') as f:
    config = json.load(f)
if 'runtimes' not in config:
    config['runtimes'] = {}
config['runtimes']['runsc'] = {
    'path': '/usr/bin/runsc',
    'runtimeArgs': ['--platform=${RUNSC_PLATFORM}']
}
with open('${DAEMON_JSON}', 'w') as f:
    json.dump(config, f, indent=2)
"
else
    info "创建新的 daemon.json"
    cat > "${DAEMON_JSON}" <<EOF
{
  "runtimes": {
    "runsc": {
      "path": "/usr/bin/runsc",
      "runtimeArgs": ["--platform=${RUNSC_PLATFORM}"]
    }
  }
}
EOF
fi

# 重启 Docker
info "重启 Docker..."
systemctl restart docker

# 等待 Docker 就绪
sleep 3
if ! docker info &>/dev/null; then
    error "Docker 重启后未就绪。请检查: journalctl -u docker"
fi

# 验证 runsc 运行时已注册
if docker info 2>/dev/null | grep -q "runsc"; then
    info "runsc 运行时已注册到 Docker"
else
    warn "未检测到 runsc 运行时。请检查 daemon.json 配置。"
fi

# ---------------------------------------------------------------------------
# 拉取镜像
# ---------------------------------------------------------------------------
info "拉取镜像 ${IMAGE_NAME}:${IMAGE_TAG}..."
docker pull "${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# 清理已有容器
# ---------------------------------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "发现同名容器 ${CONTAINER_NAME}，正在停止并删除..."
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 启动 gVisor 沙箱
# ---------------------------------------------------------------------------
info "使用 gVisor 运行时启动 FYY Agent 沙箱 (平台: ${RUNSC_PLATFORM})..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    --runtime=runsc \
    --restart unless-stopped \
    --memory 4g \
    --cpus 2.0 \
    -e FYY_SANDBOX=1 \
    -e FYY_LOG_LEVEL=info \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    -v fyy-data:/data/fyy \
    --security-opt no-new-privileges:true \
    "${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# 验证
# ---------------------------------------------------------------------------
info "等待容器启动..."
sleep 5

# 检查容器运行状态
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error "容器启动失败。查看日志: docker logs ${CONTAINER_NAME}"
fi

# 验证 gVisor 隔离
info "验证 gVisor 隔离..."
KERNEL_VERSION=$(docker exec "${CONTAINER_NAME}" uname -v 2>/dev/null || echo "unknown")
info "内核版本: ${KERNEL_VERSION}"

# 验证 fyy CLI
FYY_VERSION=$(docker exec "${CONTAINER_NAME}" fyy --version 2>/dev/null || echo "unknown")
info "fyy 版本: ${FYY_VERSION}"

# 验证沙箱环境
SANDBOX_FLAG=$(docker exec "${CONTAINER_NAME}" bash -c 'echo $FYY_SANDBOX' 2>/dev/null || echo "")
if [[ "${SANDBOX_FLAG}" == "1" ]]; then
    info "沙箱环境标识: 正常 (FYY_SANDBOX=1)"
else
    warn "沙箱环境标识异常 (FYY_SANDBOX=${SANDBOX_FLAG})"
fi

info "FYY Agent gVisor 沙箱已启动！"
info "  容器名称: ${CONTAINER_NAME}"
info "  运行时:   runsc (${RUNSC_PLATFORM})"
info "  访问地址: http://localhost:${HOST_PORT}"
info "  查看日志: docker logs -f ${CONTAINER_NAME}"
info "  运行技能: docker exec ${CONTAINER_NAME} fyy skill run <skill-name>"
