#!/usr/bin/env bash
# run.sh — FYY Agent Sandbox 一键启动脚本
#
# 使用方法:
#   ./run.sh                    # 使用默认配置启动
#   FYY_SANDBOX_TAG=1.2.0 ./run.sh  # 指定镜像版本
#
# 功能:
#   - 自动拉取最新镜像
#   - 创建命名卷用于数据持久化
#   - 启动沙箱容器并验证运行状态

set -euo pipefail

# ---------------------------------------------------------------------------
# 配置
# ---------------------------------------------------------------------------
IMAGE_NAME="feiyueyun/fyy-sandbox"
IMAGE_TAG="${FYY_SANDBOX_TAG:-latest}"
CONTAINER_NAME="fyy-sandbox"
HOST_PORT="${FYY_PORT:-8080}"
CONTAINER_PORT="8080"

# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
# 检查 Docker 是否可用
if ! command -v docker &>/dev/null; then
    error "Docker 未安装。请访问 https://docs.docker.com/get-docker/ 安装 Docker。"
fi

# 检查 Docker 守护进程是否运行
if ! docker info &>/dev/null; then
    error "Docker 守护进程未运行。请执行 sudo systemctl start docker。"
fi

# ---------------------------------------------------------------------------
# 拉取镜像
# ---------------------------------------------------------------------------
info "拉取镜像 ${IMAGE_NAME}:${IMAGE_TAG}..."
docker pull "${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# 清理已有容器（如果存在同名容器）
# ---------------------------------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "发现同名容器 ${CONTAINER_NAME}，正在停止并删除..."
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 启动沙箱容器
# ---------------------------------------------------------------------------
info "启动 FYY Agent 沙箱..."
docker run -d \
    --name "${CONTAINER_NAME}" \
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
sleep 3

# 检查容器是否运行
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error "容器启动失败。查看日志: docker logs ${CONTAINER_NAME}"
fi

# 验证 fyy CLI
info "验证 fyy CLI..."
FYY_VERSION=$(docker exec "${CONTAINER_NAME}" fyy --version 2>/dev/null || echo "unknown")
info "fyy 版本: ${FYY_VERSION}"

# 验证沙箱环境变量
info "验证沙箱环境..."
SANDBOX_FLAG=$(docker exec "${CONTAINER_NAME}" bash -c 'echo $FYY_SANDBOX' 2>/dev/null || echo "")
if [[ "${SANDBOX_FLAG}" == "1" ]]; then
    info "沙箱环境标识: 正常 (FYY_SANDBOX=1)"
else
    warn "沙箱环境标识异常 (FYY_SANDBOX=${SANDBOX_FLAG})"
fi

info "FYY Agent 沙箱已启动！"
info "  容器名称: ${CONTAINER_NAME}"
info "  访问地址: http://localhost:${HOST_PORT}"
info "  查看日志: docker logs -f ${CONTAINER_NAME}"
info "  运行技能: docker exec ${CONTAINER_NAME} fyy skill run <skill-name>"
