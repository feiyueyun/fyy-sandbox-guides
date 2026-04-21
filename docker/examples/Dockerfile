# Dockerfile — FYY Agent Sandbox 自定义镜像示例
#
# 使用方法:
#   docker build -t fyy-sandbox-custom .
#   docker run -d --name fyy-custom -e FYY_SANDBOX=1 fyy-sandbox-custom
#
# 基于官方 FYY 沙箱镜像，添加额外的系统包、Python 依赖或自定义技能。
# 修改下方注释块以适应你的项目需求。

FROM feiyueyun/fyy-sandbox:latest

# ---------------------------------------------------------------------------
# 安装额外系统包（按需取消注释）
# ---------------------------------------------------------------------------
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     ffmpeg \
#     && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 安装额外 Python 包（按需取消注释）
# ---------------------------------------------------------------------------
# RUN pip install --no-cache-dir pandas numpy

# ---------------------------------------------------------------------------
# 预装自定义技能（按需取消注释）
# ---------------------------------------------------------------------------
# COPY --chown=fyy:fyy ./my-skills/ /data/fyy/skills/

# 切换回非 root 用户
USER fyy
