# Contributing to FYY Sandbox Integration Guides

Thank you for your interest in contributing to the FYY Sandbox Integration Guides repository.

## How to Contribute

### Report Issues

Open a GitHub Issue describing the problem, including:
- Which guide is affected (docker, gvisor, e2b, etc.)
- What you expected vs. what happened
- Your environment (OS, runtime version, etc.)

### Submit Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b my-guide-update`
3. Make your changes following the guide template below
4. Submit a Pull Request against the `main` branch

## Guide Writing Template

Every guide README.md must follow this section order:

```markdown
# Running FYY Agent Sandbox with <Product Name>

<SEO-optimized description paragraph (50-150 words) incorporating target keywords>

## Prerequisites
- Software version requirements with verify commands
- System requirements
- Account requirements (if applicable)

## Quick Start
1. ≤5 steps from zero to running fyy-sandbox container
2. Each step with copy-pasteable commands
> **What's Next**: <paragraph guiding users to explore fyy CLI capabilities>

## Full Configuration Guide
### Configuration scenario 1
### Configuration scenario 2

## fyy CLI Integration Verification
- `fyy --version` version check
- `FYY_SANDBOX=1` environment variable check

## Skill Installation and Running Example
<Complete steps for installing and running a skill>
<Conversion paragraph about discovering other Agents' skills>

## Troubleshooting
| Problem | Cause | Solution |
|---------|-------|----------|
(≥3 common issues)

## Security Considerations
<Isolation level and applicable scenarios for this sandbox product>

## Learn More about FYY Platform
<FYY platform core capabilities: Mesh network, skill sharing, Grants>

## Related Links
- [fyy-sandbox-images](https://github.com/feiyueyun/fyy-sandbox-images)
- [FYY GitHub Organization](https://github.com/feiyueyun)
- Other guide cross-links
```

## Quality Standards

### Content

- **Self-contained**: Each guide must be independently usable — no "see the Docker guide first" requirements
- **Copy-pasteable**: All commands must work when copied directly to a terminal
- **Tested**: All commands should be verified against the current `feiyueyun/fyy-sandbox:latest` image
- **SEO-optimized**: Title and description paragraph should incorporate target keywords

### Image References

- Always use full image name: `feiyueyun/fyy-sandbox:<tag>`
- Default to `latest`, explain version pinning for production
- Never use abbreviated names

### Example Files

Place all configuration files and scripts in the guide's `examples/` directory:

```
<guide>/
├── README.md
└── examples/
    ├── <config-file>
    └── <script>.sh
```

Shell scripts must include:
- Shebang: `#!/usr/bin/env bash`
- Error handling: `set -euo pipefail`
- Inline comments explaining each option
- Executable permission: `chmod +x`

Configuration files must include:
- Detailed inline comments
- Default values with explanations

### Cross-References

Link to example files using relative paths:
```markdown
See [docker-compose.yml](examples/docker-compose.yml) for a complete example.
```

Link to other guides using relative paths:
```markdown
See the [gVisor guide](../gvisor/) for kernel-level isolation.
```

## Directory Structure

```
fyy-sandbox-guides/
├── README.md                 # This overview
├── CONTRIBUTING.md           # This file
├── LICENSE                   # BSD 3-Clause
├── .github/workflows/ci.yml  # CI checks
├── .markdown-link-check.json # Link checker config
├── docker/                   # Docker/Podman guide
│   ├── README.md
│   └── examples/
├── gvisor/                   # gVisor (runsc) guide
│   ├── README.md
│   └── examples/
├── e2b/                      # E2B cloud sandbox guide
│   ├── README.md
│   └── examples/
├── devcontainer/             # Phase 2
├── daytona/                  # Phase 2
├── firecracker/              # Phase 2
├── kata/                     # Phase 2
└── kubernetes/               # Phase 2
```

## PR Review Checklist

Reviewers will check:

- [ ] All required sections present in correct order
- [ ] Commands are copy-pasteable and tested
- [ ] Image references use full name `feiyueyun/fyy-sandbox:<tag>`
- [ ] Example files have inline comments
- [ ] Shell scripts have shebang and `set -euo pipefail`
- [ ] Relative path links resolve correctly
- [ ] No hard-sell language in conversion paragraphs
- [ ] First mention uses full name「飞越云 AI 数字员工平台（FYY）」
