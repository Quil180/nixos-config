# NixOS Configuration (Flake-based)

## Introduction

This repository contains a modular, flake-based NixOS configuration designed for a primary workstation (laptop) and multiple specialized server nodes. It leverages modern Nix ecosystem tools for reproducible, declarative, and secure system management.

## Table of Contents

- [Systems](#systems)
- [Key Technologies](#key-technologies)
- [Installation](#installation)
- [Maintenance](#maintenance)
- [Repository Structure](#repository-structure)
- [To-Do](#to-do)

## Systems

This flake defines multiple NixOS configurations tailored for different hardware and roles:

- **`snowflake`**: Primary workstation (Asus Zephyrus G14 GA402RK). 
  - Features: Hyprland (Wayland), G14-specific kernel/hardware optimizations, AMD GPU support, and Impermanence (ephemeral root).
- **Servers**: Multiple specialized Proxmox VMs (`baguette`, `biscotti`, `croissant`, `crust`, `macaron`, `muffin`, `pancake`, `scone`).
  - Common features: Headless operation, secure SSH, node-exporter for monitoring, and service-specific secrets.

## Key Technologies

- **[Nix Flakes](https://nixos.wiki/wiki/Flakes)**: For reproducible builds and precise dependency management.
- **[Home Manager](https://github.com/nix-community/home-manager)**: Manages user-specific environments and dotfiles.
- **[Agenix](https://github.com/ryantm/agenix)**: Age-encrypted secrets managed via Nix (e.g., passwords, API tokens).
- **[Disko](https://github.com/nix-community/disko)**: Declarative disk partitioning and formatting.
- **[Stylix](https://github.com/danth/stylix)**: System-wide uniform theming (colors, fonts, wallpapers).
- **[Hyprland](https://hyprland.org/)**: A dynamic tiling Wayland compositor that doesn't sacrifice on appearance.
- **[Impermanence](https://github.com/nix-community/impermanence)**: For a clean, ephemeral root filesystem that resets on every boot.

## Installation

The included `install.sh` script provides a comprehensive installation menu. It handles disk partitioning (via Disko), system installation, and initial home-manager setup.

To start the installation from a NixOS ISO:

```bash
curl -LJ0 https://raw.githubusercontent.com/Quil180/nixos-config/refs/heads/install.sh > install.sh
chmod +x install.sh
./install.sh
```

Select **Option 1 (Fresh Install)** and follow the prompts to choose your system and user.

## Maintenance

The `install.sh` script also serves as a management utility for post-installation tasks:

- **Rebuild System**: `./install.sh system` (runs `nixos-rebuild switch`)
- **Rebuild Home**: `./install.sh home` (runs `home-manager switch`)
- **Update Flake**: `./install.sh update` (runs `nix flake update`)

## Repository Structure

- `flake.nix`: Entry point for the entire configuration.
- `install.sh`: Installation and maintenance script.
- `secrets/`: Age-encrypted secrets and `secrets.nix` definitions.
- `system/`: NixOS system configurations.
  - `snowflake/`: Specific configuration for the G14 laptop.
  - `servers/`: Specific configurations for server nodes.
  - `universal/`: Shared system-wide modules (GUI, services, hardware).
- `users/`: Home-manager user configurations.
  - `quil/`: Primary user profile.
  - `universal/`: Shared user-level modules (applications, ricing).
- `wallpapers/`: A collection of system-wide wallpapers managed by Stylix.

## To-Do

- [ ] Refine Impermanence setup for server nodes.
- [ ] Refine Impermanence setup for Home-Manager.
- [ ] Automate backup strategy for persistent data.
