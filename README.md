# NixOS Configuration

## Introduction

This repository contains the NixOS configuration files for setting up and managing a NixOS system. It includes installation scripts, user-specific configurations, system settings, and additional resources like wallpapers.

## Table of Contents

- [Installation](#installation)
- [Post-Installation Setup](#post-installation-setup)
- [Installing Additional Software](#installing-additional-software)
  - [Vivado/Xilinx](#vivadoxilinx)
- [Repository Structure](#repository-structure)
- [To-Do](#To-Do)

## Installation

To install this NixOS configuration, execute the following commands:

```bash
curl -LJ0 https://raw.githubusercontent.com/Quil180/nixos-config/refs/heads/install.sh > install.sh
chmod +x install.sh
./install.sh
```

During the installation process:

- **Phase 1**: Select this if you're running from the NixOS ISO installer.
- **Phase 2**: Choose this if you're operating from the local SSD or hard drive.

## Post-Installation Setup

After installation, set up an SSH key for GitHub access:

```bash
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -C "email@url.com"
cat id_rsa.pub
```

Copy the output and add it to your GitHub account under SSH keys.

## Installing Additional Software

### Vivado/Xilinx

To install Vivado/Xilinx:

1. Download the `Xilinx_Unified_XXXX.X_XXXX_XXXX_Lin64.bin` installer from the AMD website and make it executable:

   ```bash
   chmod +x Xilinx_Unified_XXXX.X_XXXX_XXXX_Lin64.bin
   ```

2. Run the installer within a Nix shell:

   ```bash
    nix --option extra-experimental-features 'nix-command flakes' run gitlab:doronbehar/nix-xilinx#xilinx-shell
   ```

   Follow the prompts and install the software in a user-writable directory, such as `~/Documents`.

3. Create the configuration script at `~/.config/xilinx/nix.sh` with the following content:

   ```bash
    INSTALL_DIR=$HOME/downloads/software/xilinx
    # The directory in which there's a /bin/ directory for each product, for example:
    # $HOME/downloads/software/xilinx/Vivado/YEAR.VERSION/bin
    VERSION=YEAR/VERSION
   ```

   Replace `YEAR.VERSION` with the appropriate version number.

4. To integrate Vivado into your system's application menu, refer to the [nix-xilinx GitLab repository](https://gitlab.com/doronbehar/nix-xilinx) for detailed instructions.

## Repository Structure

- `packages/`: Custom package definitions, e.g., `neovim`.
- `secrets/`: Encrypted or sensitive configuration files.
- `system/`: System-wide NixOS configurations.
- `users/`: User-specific configurations.
- `wallpapers/`: Collection of wallpapers for the system.

For more detailed information, explore the respective directories and files within this repository. 

## To-Do
- Make secrets actually work!!!!
