# Kelmora Installer

Kelmora Installer is a modular Bash project for onboarding and provisioning supported Debian and Ubuntu VPS instances.

The first milestone is complete: local platform detection, a responsive terminal onboarding flow, plan review, and a transactional core installation path.

## What it does now

- Detects the OS, version, package manager, CPU architecture, virtualisation, memory, storage, network interface, `systemd`, and BBR capability without contacting a remote service.
- Supports Debian 12+ and Ubuntu 22.04+ on `amd64` and `arm64` with APT.
- Provides a keyboard-first onboarding experience that adapts to non-colour and non-interactive terminals.
- Builds a transparent installation plan before making any system change.
- Installs only packages found in the VPS's configured signed APT repositories.
- Owns a narrow, documented set of Kelmora files and can remove them cleanly.
- Retains APT packages on uninstall so it never removes tools that may have become part of the user's workflow.

It intentionally does **not** run remote `curl | bash` installers, add unverified third-party repositories, change firewall rules, or provision web/database/game-panel workloads automatically. Those will become separately reviewed modules with explicit user consent.

## Run

Copy the complete `kelmora-installer` folder to the VPS and run from its root:

```bash
sudo bash kelmora-installer
```

Useful commands:

```bash
# Examine compatibility without changing the VPS.
bash kelmora-installer detect

# Show the default plan without changing the VPS.
sudo bash kelmora-installer plan

# Run onboarding but stop before making changes.
sudo bash kelmora-installer onboard --dry-run

# Non-interactive, default-profile install.
sudo bash kelmora-installer install --yes

# Update system packages and redeploy Kelmora.
sudo bash kelmora-installer update --yes

# Remove Kelmora-owned files only.
sudo bash kelmora-installer uninstall --yes
```

## Project layout

```text
kelmora-installer/
├── kelmora-installer     Entry point and command routing
├── lib/
│   ├── common.sh          Runtime safety, logging, and options
│   ├── ui.sh              Adaptive terminal visual system and prompts
│   ├── platform.sh        VPS detection and support policy
│   ├── plan.sh            Profiles and explicit installation plan
│   ├── onboarding.sh      Guided first-run state machine
│   └── install.sh         Transactional deploy, update, and uninstall
└── tests/
    └── test-platform.sh   Portable unit tests for support policy
```

## Supported-platform policy

| OS | Version | Architecture |
| --- | --- | --- |
| Ubuntu | 22.04 or newer | amd64, arm64 |
| Debian | 12 or newer | amd64, arm64 |

Unsupported systems are detected before any write or package operation. Detection only reads local files and commands; it does not use provider metadata or external endpoints.

## Update trust model

This project updates packages from the VPS's already configured, signed APT sources. Updating the installer code itself requires obtaining a newer Kelmora release through Kelmora's future signed release channel; it does not silently fetch or execute an arbitrary URL. A production release channel should use a Kelmora-controlled domain, versioned manifests, checksums, and a bundled public key.
