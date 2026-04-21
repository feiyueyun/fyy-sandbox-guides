# 实施任务：沙箱集成指南（fyy-sandbox-guides Phase 1）

## 1. 仓库骨架与根目录文档
- [x] 1.1 Create repository directory structure: `docker/`, `docker/examples/`, `gvisor/`, `gvisor/examples/`, `e2b/`, `e2b/examples/`, `.github/workflows/`
- [x] 1.2 Create `LICENSE` file with BSD 3-Clause full text
- [x] 1.3 Create root `README.md` with sections: project intro (首次使用全称「飞越云 AI 数字员工平台」), available guides list with links, fyy-sandbox image overview, two-layer sandbox model summary, license
- [x] 1.4 Create `CONTRIBUTING.md` with guide writing template, directory structure conventions, quality standards, and PR process

## 2. Docker/Podman 集成指南（Alpha）
- [x] 2.1 Create `docker/README.md` with title `# Running FYY Agent Sandbox with Docker and Podman` and SEO description paragraph (50-150 words) incorporating keywords: `Docker Agent runtime environment`, `Docker AI Agent sandbox`, `Podman Agent sandbox`
- [x] 2.2 Write Prerequisites section: Docker Engine 20.10+ or Podman 4.0+, version check commands
- [x] 2.3 Write Quick Start section (≤5 steps): pull image, start container, verify fyy CLI; include image tag note about `latest` vs version pinning; add "What's Next" paragraph guiding users to `fyy join` mesh networking
- [x] 2.4 Write Full Configuration Guide section: custom container name, env vars, volume mounts (fyy CLI data dir), network config (host vs bridge), resource limits (CPU/memory); provide both Docker and Podman command variants where they differ
- [x] 2.5 Write fyy CLI Integration Verification section: `fyy --version` and `FYY_SANDBOX=1` env var detection
- [x] 2.6 Write Skill Installation and Running Example section with full steps; add conversion paragraph about discovering and calling other Agents' skills via fyy CLI
- [x] 2.7 Write Troubleshooting section with ≥3 common issues and solutions
- [x] 2.8 Write Security Considerations section: runc isolation level, non-root user benefits, comparison with gVisor
- [x] 2.9 Write "Learn More about FYY Platform" section (Mesh network, skill sharing, Grants) and Related Links section (fyy-sandbox-images, FYY GitHub org, fyy CLI install)

## 3. Docker/Podman 示例文件与 CI 验证
- [x] 3.1 Create `docker/examples/docker-compose.yml` with inline comments explaining each config option
- [x] 3.2 Create `docker/examples/run.sh` with shebang, `set -euo pipefail`, usage comments, executable permission
- [x] 3.3 Create `docker/examples/ci-verify.sh` implementing all verification steps: pull image, start container, verify `fyy --version` (exit 0), verify `FYY_SANDBOX=1`, verify Python/Node.js runtimes, verify non-root user, cleanup; support `FYY_SANDBOX_TAG` env var; output `[PASS]`/`[FAIL]` per step
- [x] 3.4 Create `.github/workflows/ci-verify.yml` GitHub Actions workflow: trigger on push/PR to `docker/**` and weekly schedule; run `ci-verify.sh`

## 4. gVisor (runsc) 集成指南（Alpha）
- [x] 4.1 Create `gvisor/README.md` with title `# Running FYY Agent Sandbox with gVisor (runsc)` and SEO description paragraph incorporating keywords: `gVisor Agent sandbox`, `Agent isolated execution environment`, `runsc container runtime`
- [x] 4.2 Write Prerequisites section: gVisor runsc installation requirements, version check commands
- [x] 4.3 Write Quick Start section: install runsc, configure Docker runtime, pull image, run with `--runtime=runsc`, verify fyy CLI; include image tag note; add "What's Next" paragraph
- [x] 4.4 Write Full Configuration Guide section: daemon.json runsc config, Podman runsc config, gVisor platform selection (systrap vs KVM), compatibility notes
- [x] 4.5 Write fyy CLI Integration Verification section
- [x] 4.6 Write Skill Installation and Running Example section with conversion paragraph
- [x] 4.7 Write Troubleshooting section (≥3 issues)
- [x] 4.8 Write Security Considerations section: gVisor user-space kernel advantages, syscall interception, comparison with runc, performance overhead
- [x] 4.9 Write scope clarification: this guide covers Layer 1 (gVisor as OCI runtime for entire container), not Layer 2 (CLI internal skill isolation); explain automatic Layer 2 degradation to process-level when running inside gVisor
- [x] 4.10 Write "Learn More about FYY Platform" and Related Links sections

## 5. gVisor 示例文件
- [x] 5.1 Create `gvisor/examples/daemon.json` with runsc runtime definition and inline comments
- [x] 5.2 Create `gvisor/examples/run-gvisor.sh` with shebang, `set -euo pipefail`, usage comments, executable permission

## 6. E2B 集成指南（Beta）
- [x] 6.1 Create `e2b/README.md` with title `# Running FYY Agent Sandbox with E2B` and SEO description paragraph incorporating keywords: `E2B Agent sandbox setup`, `E2B AI Agent`, `cloud Agent sandbox`
- [x] 6.2 Write Prerequisites section: E2B account, E2B CLI installation, API Key configuration
- [x] 6.3 Write Quick Start section: configure E2B custom sandbox template with fyy-sandbox image; include image tag note; add "What's Next" paragraph
- [x] 6.4 Write Full Configuration Guide section: E2B Dockerfile config (based on fyy-sandbox), env vars, timeout and resource config; configuration-level only, no SDK code examples
- [x] 6.5 Write fyy CLI Integration Verification section
- [x] 6.6 Write Skill Installation and Running Example section with conversion paragraph
- [x] 6.7 Write Troubleshooting section (≥3 issues)
- [x] 6.8 Write Security Considerations section: E2B Firecracker microVM isolation model and advantages
- [x] 6.9 Write "Learn More about FYY Platform" and Related Links sections

## 7. E2B 示例文件
- [x] 7.1 Create `e2b/examples/e2b.Dockerfile` with inline comments (based on fyy-sandbox image)
- [x] 7.2 Create `e2b/examples/e2b.toml` with E2B sandbox configuration and inline comments

## 8. 跨指南一致性与最终验证
- [x] 8.1 Verify all guides use consistent full image name format `feiyueyun/fyy-sandbox:<tag>` throughout; default to `latest`, mention version pinning
- [x] 8.2 Verify all guides contain all required sections in correct order per design template
- [x] 8.3 Verify all `examples/` relative path links in guide READMEs resolve correctly
- [x] 8.4 Verify all example scripts have shebang, `set -euo pipefail`, and executable permission
- [x] 8.5 Verify root README guide list links point to correct directories
- [ ] 8.6 Run `ci-verify.sh` locally (or verify script logic) to confirm Docker guide CI verification works end-to-end