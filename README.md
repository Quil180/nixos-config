# ❄️ Quil180's NixOS Configuration

> A highly modular, flake-based NixOS configuration leveraging a **dendritic pattern** for scalable, reproducible system and user management across a fleet of machines.

This repository manages my primary workstation (`snowflake`) and a homelab fleet of Proxmox VMs. It utilizes modern Nix ecosystem tools to ensure a fully declarative, secure, and ephemeral environment.

---

## 🖥️ Systems

The flake defines multiple NixOS configurations tailored to their specific hardware and roles:

| Hostname | Role | Key Features |
| :--- | :--- | :--- |
| **`snowflake`** | Primary Workstation | Asus Zephyrus G14 (GA402RK) laptop, Hyprland (Wayland), AMD GPU optimizations, `nixos-hardware` integration, and ephemeral root via **Impermanence**. |
| **`baguette`** | Server Node | Headless Proxmox VM. Secure SSH, Node Exporter monitoring, and service-specific secrets. |
| **`biscotti`** | Server Node | Headless Proxmox VM. |
| **`croissant`** | Server Node | Headless Proxmox VM. |
| **`crust`** | Server Node | Headless Proxmox VM. |
| **`macaron`** | Server Node | Headless Proxmox VM. |
| **`muffin`** | Server Node | Headless Proxmox VM. |
| **`pancake`** | Server Node | Headless Proxmox VM. |
| **`scone`** | Server Node | Headless Proxmox VM. |

---

## 🛠️ Key Technologies & Stack

This configuration relies on a robust, modern Nix ecosystem:

### Core Framework
- **[Nix Flakes](https://nixos.wiki/wiki/Flakes)** & **[Flake Parts](https://github.com/hercules-ci/flake-parts)**: Precise dependency management and structured flake outputs.
- **[Import-Tree](https://github.com/vic/import-tree)**: Enables the "dendritic pattern" for highly modular, automated NixOS and Home Manager module loading.
- **[Disko](https://github.com/nix-community/disko)**: Declarative, reproducible disk partitioning and formatting.
- **[Impermanence](https://github.com/nix-community/impermanence)**: Maintains a clean, ephemeral root filesystem that resets on every boot, persisting only explicitly declared state.

### User Environment & Theming
- **[Home Manager](https://github.com/nix-community/home-manager)**: Declarative dotfiles, shell configurations, and user environments.
- **[Stylix](https://github.com/danth/stylix)**: System-wide uniform theming (colorschemes, fonts, and wallpapers).
- **[Hyprland](https://github.com/hyprwm/Hyprland)**: Dynamic tiling Wayland compositor, configured with plugins like `split-monitor-workspaces` and `rose-pine-hyprcursor`.
- **[Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell)** & **[NixCord](https://github.com/kaylorben/nixcord)**: Custom desktop tools and UI elements.
- **[Nix Flatpak](https://github.com/gmodena/nix-flatpak)**: Declarative Flatpak application management.

### Security & Development
- **[Agenix](https://github.com/ryantm/agenix)**: Age-encrypted secrets managed via Nix (passwords, API tokens, SSH keys).
- **[Rust Overlay](https://github.com/oxalica/rust-overlay)**: Development toolchains.
- **[Jovian NixOS](https://github.com/Jovian-Experiments/Jovian-NixOS)** & **[Hermes Agent](https://github.com/NousResearch/hermes-agent)**: Specialized hardware/gaming tweaks and local AI/LLM integrations.

---

## 📂 Repository Structure

```text
.
├── flake.nix              # Flake entry point (managed via flake-parts & import-tree)
├── flake.lock             # Pinned dependency lockfile
├── install.sh             # Interactive installation and maintenance script
├── secrets/               # Agenix encrypted secrets and `secrets.nix` definitions
├── system/                # NixOS system configurations
│   ├── snowflake/         # Primary workstation (G14 laptop)
│   ├── servers/           # Server node configurations (Proxmox VMs)
│   └── universal/         # Shared system-wide modules (hardware, services)
├── users/                 # Home Manager user configurations
│   ├── quil/              # Primary user profile
│   └── universal/         # Shared user-level modules (applications, ricing)
├── shells/verilog/        # Specialized development shells
└── wallpapers/            # Git submodule for system-wide wallpapers
```

---

## 🚀 Installation & Maintenance

This repository includes a robust, interactive CLI script (`install.sh`) designed to handle fresh installations from a live ISO, post-boot setups, and daily maintenance. 

The script features resumable checkpoints, flake validation, network checks, and safeguards against disk-wiping accidents.

### Running the Manager
```bash
./install.sh
```
This will launch an interactive menu, or you can pass commands directly:

| Command | Alias | Description |
| :--- | :--- | :--- |
| `install` | `fresh` | Performs a fresh install from a Live ISO. Handles networking, validates the flake, wipes/partitions disks via Disko, bypasses RAM limits via overlay, installs NixOS, and bootstraps Home Manager. |
| `post` | `setup` | Post-installation setup. Initializes submodules and runs Home Manager after the first boot. |
| `system` | `rebuild` | Rebuilds and switches the NixOS system configuration (`sudo nixos-rebuild switch`). |
| `home` | | Rebuilds and switches Home Manager configurations. |
| `update` | | Updates all flake inputs and regenerates `flake.lock`. |
| `reset` | | Clears the installation checkpoint file (useful to restart a failed `install` sequence). |

---

## 🔐 Secrets Management (Agenix)

Secrets are encrypted using **Agenix** and stored in the `secrets/` directory. 

> ⚠️ **Note for Fresh Installs:** 
> Because `agenix` relies on the host's SSH keys to decrypt secrets, a freshly installed machine will have a brand new host key. The `install.sh` script will pause and remind you to extract the new public key and run `agenix rekey` from your development machine (or after first boot) before secrets will decrypt successfully.

### Rekeying Secrets
After changing a secret or adding a new host:
```bash
agenix -e secrets/<secret_name>.age
# or
agenix rekey
```

---

## 🔄 Updating the System

To pull the latest changes and update system/user packages:

1. **Update Flake Inputs:**
   ```bash
   ./install.sh update
   # or: nix flake update --flake ~/.dotfiles
   ```
2. **Rebuild System & Home:**
   ```bash
   ./install.sh system
   ./install.sh home
   ```
