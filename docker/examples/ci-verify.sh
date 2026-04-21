#!/usr/bin/env bash
# ci-verify.sh — FYY Agent Sandbox Docker 集成验证脚本
#
# 用于 CI/CD 管道中验证沙箱镜像的功能完整性。
# 也可在本地运行以验证部署是否正常。
#
# 使用方法:
#   ./ci-verify.sh                          # 使用默认配置验证
#   FYY_SANDBOX_TAG=1.2.0 ./ci-verify.sh    # 验证指定版本
#
# 环境变量:
#   FYY_SANDBOX_TAG  — 镜像版本标签 (默认: latest)
#   FYY_SANDBOX_IMAGE — 完整镜像名 (默认: feiyueyun/fyy-sandbox:${FYY_SANDBOX_TAG})
#
# 输出格式:
#   [PASS] Step N: <描述>
#   [FAIL] Step N: <描述> — <错误信息>

set -euo pipefail

# ---------------------------------------------------------------------------
# 配置
# ---------------------------------------------------------------------------
IMAGE_TAG="${FYY_SANDBOX_TAG:-latest}"
IMAGE_NAME="${FYY_SANDBOX_IMAGE:-feiyueyun/fyy-sandbox:${IMAGE_TAG}}"
CONTAINER_NAME="fyy-ci-verify-$$"

# 计数器
PASS_COUNT=0
FAIL_COUNT=0
STEP=0

# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
pass() {
    STEP=$((STEP + 1))
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "[PASS] Step ${STEP}: $*"
}

fail() {
    STEP=$((STEP + 1))
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "[FAIL] Step ${STEP}: $*"
}

cleanup() {
    # 清理测试容器
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Step 1: 拉取镜像
# ---------------------------------------------------------------------------
echo "=== FYY Sandbox Docker CI Verification ==="
echo "Image: ${IMAGE_NAME}"
echo ""

docker pull "${IMAGE_NAME}" 2>/dev/null
if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
    pass "Image pull — ${IMAGE_NAME}"
else
    fail "Image pull — 无法拉取镜像 ${IMAGE_NAME}"
fi

# ---------------------------------------------------------------------------
# Step 2: 启动容器
# ---------------------------------------------------------------------------
docker run -d \
    --name "${CONTAINER_NAME}" \
    -e FYY_SANDBOX=1 \
    "${IMAGE_NAME}" 2>/dev/null

sleep 3

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    pass "Container start — 容器正常运行"
else
    fail "Container start — 容器未能正常启动"
    # 输出日志以帮助调试
    docker logs "${CONTAINER_NAME}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Step 3: 验证 fyy --version
# ---------------------------------------------------------------------------
FYY_VERSION=$(docker exec "${CONTAINER_NAME}" fyy --version 2>/dev/null || echo "")
if [[ -n "${FYY_VERSION}" ]]; then
    pass "fyy CLI — 版本 ${FYY_VERSION}"
else
    fail "fyy CLI — fyy --version 无输出"
fi

# ---------------------------------------------------------------------------
# Step 4: 验证 FYY_SANDBOX 环境变量
# ---------------------------------------------------------------------------
SANDBOX_FLAG=$(docker exec "${CONTAINER_NAME}" bash -c 'echo $FYY_SANDBOX' 2>/dev/null || echo "")
if [[ "${SANDBOX_FLAG}" == "1" ]]; then
    pass "FYY_SANDBOX env — FYY_SANDBOX=1"
else
    fail "FYY_SANDBOX env — 期望值为 1，实际为 '${SANDBOX_FLAG}'"
fi

# ---------------------------------------------------------------------------
# Step 5: 验证 Python 运行时
# ---------------------------------------------------------------------------
PYTHON_VERSION=$(docker exec "${CONTAINER_NAME}" python3 --version 2>/dev/null || echo "")
if [[ "${PYTHON_VERSION}" == Python* ]]; then
    pass "Python runtime — ${PYTHON_VERSION}"
else
    fail "Python runtime — python3 --version 无输出或异常"
fi

# ---------------------------------------------------------------------------
# Step 6: 验证 Node.js 运行时
# ---------------------------------------------------------------------------
NODE_VERSION=$(docker exec "${CONTAINER_NAME}" node --version 2>/dev/null || echo "")
if [[ "${NODE_VERSION}" == v* ]]; then
    pass "Node.js runtime — ${NODE_VERSION}"
else
    fail "Node.js runtime — node --version 无输出或异常"
fi

# ---------------------------------------------------------------------------
# Step 7: 验证非 root 用户
# ---------------------------------------------------------------------------
CURRENT_USER=$(docker exec "${CONTAINER_NAME}" whoami 2>/dev/null || echo "")
if [[ "${CURRENT_USER}" != "root" ]]; then
    pass "Non-root user — 当前用户为 '${CURRENT_USER}'"
else
    fail "Non-root user — 容器以 root 用户运行，存在安全风险"
fi

# ---------------------------------------------------------------------------
# 结果汇总
# ---------------------------------------------------------------------------
echo ""
echo "=== Verification Summary ==="
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"
echo "Total:  $((PASS_COUNT + FAIL_COUNT))"

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    echo ""
    echo "Some verification steps failed. Please check the output above."
    exit 1
fi

echo ""
echo "All verification steps passed!"
exit 0
