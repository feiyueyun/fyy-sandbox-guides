# FYY Sandbox Integration Guides

Step-by-step guides for running [FYY CLI](https://github.com/feiyueyun/fyy) in popular sandbox and container runtimes.

Each guide is a standalone integration tutorial — pick the runtime that fits your setup.

## Available Guides

| Runtime | Description | Guide |
|---------|-------------|-------|
| Docker / Podman | Standard OCI container runtime | [docker/](docker/) |
| gVisor (runsc) | User-space kernel sandbox | [gvisor/](gvisor/) |
| Kata Containers | CNCF lightweight VM runtime | [kata/](kata/) |
| Daytona | Development environment manager (18K+ Stars) | [daytona/](daytona/) |
| E2B | Cloud Agent sandbox (YC S23) | [e2b/](e2b/) |
| Devcontainer | OCI standard dev environments (VS Code / Codespaces) | [devcontainer/](devcontainer/) |
| Firecracker | AWS microVM runtime | [firecracker/](firecracker/) |
| Kubernetes | RuntimeClass-based pod sandboxing | [kubernetes/](kubernetes/) |

## Quick Start

All guides use [fyy-sandbox-images](https://github.com/feiyueyun/fyy-sandbox-images) as the base OCI image:

```bash
docker pull feiyueyun/fyy-sandbox:latest
```

Then follow the guide for your runtime.

## License

BSD 3-Clause — see [LICENSE](LICENSE).

> 🚧 Guide content will be filled as FYY CLI v1.0-alpha is released (2026 Q3). Docker/Podman, Devcontainer, and E2B guides will be published first.
