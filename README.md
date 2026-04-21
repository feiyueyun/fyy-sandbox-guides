# FYY Sandbox Integration Guides

Step-by-step guides for running [FYY CLI](https://github.com/feiyueyun/fyy) in popular sandbox and container runtimes.

Each guide is a standalone integration tutorial — pick the runtime that fits your setup.

## Available Guides

| Runtime | Description | Phase | Guide |
|---------|-------------|-------|-------|
| Docker / Podman | Standard OCI container runtime | 1 | [docker/](docker/) |
| gVisor (runsc) | User-space kernel sandbox | 1 | [gvisor/](gvisor/) |
| E2B | Cloud Agent sandbox (YC S23) | 1 | [e2b/](e2b/) |
| Devcontainer | OCI standard dev environments (VS Code / Codespaces) | 2 | [devcontainer/](devcontainer/) |
| Daytona | Development environment manager (18K+ Stars) | 2 | [daytona/](daytona/) |
| Kata Containers | CNCF lightweight VM runtime | 2 | [kata/](kata/) |
| Firecracker | AWS microVM runtime | 2 | [firecracker/](firecracker/) |
| Kubernetes | RuntimeClass-based pod sandboxing | 2 | [kubernetes/](kubernetes/) |

## Quick Start

All guides use [fyy-sandbox-images](https://github.com/feiyueyun/fyy-sandbox-images) as the base OCI image:

```bash
docker pull feiyueyun/fyy-sandbox:latest
```

Then follow the guide for your runtime.

## FYY Sandbox Image

The `feiyueyun/fyy-sandbox` image is the foundation for all integration guides:

- **fyy CLI** — pre-installed at `/usr/local/bin/fyy`
- **Python 3.12** — with `pip3` and `venv`
- **Node.js 22 LTS** — with `npm`
- **Non-root user** — runs as `fyy` (UID 1000) by default
- **Sandbox marker** — `FYY_SANDBOX=1` environment variable

Framework-specific images are also available: `feiyueyun/fyy-sandbox:crewai`, `feiyueyun/fyy-sandbox:langgraph`.

## Two-Layer Sandbox Model

FYY uses a two-layer sandbox architecture for defense-in-depth:

```
Layer 1: Agent Runtime Sandbox (these guides)
  ├── OCI standard image (fyy-sandbox-images), fyy CLI pre-installed
  ├── Guides teach how to run these images in different sandbox products
  └── Phase 1 covers 3 sandbox products: Docker/Podman, gVisor (runsc), E2B

Layer 2: Skill Process Sandbox (fyy CLI internal, not covered here)
  ├── gVisor (runsc) locked implementation, for Skill process isolation
  ├── Three-level progressive isolation: process → seccomp → gVisor
  └── When running inside Layer 1, auto-downgrades to process-level
```

**Key distinction**: The gVisor guide covers Layer 1 (using gVisor as the OCI runtime for the entire fyy-sandbox container), not Layer 2 (CLI internal Skill process isolation). When fyy CLI detects it is running inside a gVisor container, Layer 2 automatically downgrades to process-level isolation since gVisor cannot nest.

## License

BSD 3-Clause — see [LICENSE](LICENSE).
