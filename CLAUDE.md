# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FYY Sandbox Integration Guides — a public documentation repository (BSD 3-Clause) providing step-by-step guides for running the [FYY CLI](https://github.com/feiyueyun/fyy) in various sandbox and container runtimes. Each guide is an independent customer acquisition entry point for the Feiyueyun AI Agent platform.

All guides reference the base OCI image `feiyueyun/fyy-sandbox:latest` built in the [fyy-sandbox-images](https://github.com/feiyueyun/fyy-sandbox-images) repo.

## Repository Structure

Each guide is a top-level directory containing `README.md` (guide content) and `examples/` (config files and scripts):

- **Phase 1 (complete)**: `docker/`, `gvisor/`, `e2b/` — full guides with examples
- **Phase 2 (future)**: `daytona/`, `devcontainer/`, `firecracker/`, `kata/`, `kubernetes/` — placeholder READMEs only

The `.kiro/specs/` directory contains the Phase 1 requirements, design, and task documents (in Chinese). This repo follows the Kiro spec workflow: requirements → design → tasks → implementation.

## Guide Content Template

Every guide README must follow this section order:
1. Title: `# Running FYY Agent Sandbox with <Product Name>`
2. SEO description paragraph (50-150 words, incorporating target keywords)
3. Prerequisites (with version check commands)
4. Quick Start (≤5 steps, with "What's Next" paragraph after)
5. Full Configuration Guide
6. fyy CLI Integration Verification (`fyy --version`, `FYY_SANDBOX=1`)
7. Skill Installation and Running Example (with conversion paragraph)
8. Troubleshooting (≥3 issues)
9. Security Considerations
10. Learn More about FYY Platform
11. Related Links

## Key Conventions

- **Image references**: Always use full name `feiyueyun/fyy-sandbox:<tag>`, default to `latest`, mention version pinning for production
- **Shell scripts**: Must include `#!/usr/bin/env bash`, `set -euo pipefail`, inline comments, and executable permission
- **Config files**: Must include detailed inline comments
- **Links to examples**: Use relative paths (e.g., `[view config](examples/docker-compose.yml)`)
- **First mention**: Use full name「飞越云 AI 数字员工平台（FYY）」, then abbreviate as「飞越云」or FYY
- **Two-layer sandbox model**: Layer 1 = Agent Runtime Sandbox (these guides), Layer 2 = Skill Process Sandbox (internal to fyy CLI, not covered here). gVisor guide must clarify this distinction and explain Layer 2 auto-degradation to process-level when running inside gVisor.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`):
- Checks that required guide READMEs exist (`docker/`, `gvisor/`, `e2b/`)
- Verifies all required sections are present in each guide
- Runs markdown link checking (uses `gaurav-nelson/github-action-markdown-link-check@v1`, config in `.markdown-link-check.json`)
- Docker CI verification script (`docker/examples/ci-verify.sh`):
  - Triggered on push/PR and weekly schedule
  - Validates: image pull, container start, `fyy --version`, `FYY_SANDBOX=1` env var, Python/Node.js runtimes, non-root user
  - Supports `FYY_SANDBOX_TAG` env var for testing different image versions
  - Output format: `[PASS] Step N: <desc>` / `[FAIL] Step N: <desc> — <error>`

## SEO Keywords per Guide

| Guide | Primary | Secondary |
|-------|---------|-----------|
| Docker/Podman | `Docker Agent runtime environment` | `Docker AI Agent sandbox`, `Podman Agent sandbox` |
| gVisor | `gVisor Agent sandbox` | `Agent isolated execution environment`, `runsc container runtime` |
| E2B | `E2B Agent sandbox setup` | `E2B AI Agent`, `cloud Agent sandbox` |
