#!/usr/bin/env bash
# NixOS Installation Script
# This script installs NixOS with home-manager in a single phase

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Error handler
trap 'log_error "Script failed at line $LINENO. Exit code: $?"' ERR

# Default values
DEFAULT_SYSTEM="snowflake"
DEFAULT_USER="quil"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root for install operations
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
}

# Check if we're in the live ISO environment
is_live_iso() {
    [[ -d /mnt ]] && [[ "$(whoami)" == "nixos" || ! -f /etc/NIXOS_LUSTRATE ]]
}

# Prompt with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    read -rp "${prompt} [${default}]: " result
    echo "${result:-$default}"
}

# Confirm action
confirm() {
    local prompt="$1"
    local response

    read -rp "${prompt} (y/N): " response
    [[ "${response,,}" =~ ^(yes|y)$ ]]
}

# Display disk warning
disk_warning() {
    echo ""
    log_warn "⚠️  WARNING: This will COMPLETELY ERASE the target disk!"
    log_warn "All data on the disk will be permanently destroyed."
    echo ""
}

# Fresh install from live ISO
fresh_install() {
    log_info "Starting fresh NixOS installation..."

    local system_choice
    local user_choice

    system_choice=$(prompt_with_default "What system are you installing" "$DEFAULT_SYSTEM")
    user_choice=$(prompt_with_default "What user is being installed" "$DEFAULT_USER")

    # Verify disko config exists
    local disko_config="${SCRIPT_DIR}/system/${system_choice}/disko.nix"
    if [[ ! -f "$disko_config" ]]; then
        log_error "Disko configuration not found: $disko_config"
        exit 1
    fi

    # Verify flake configuration exists
    if ! nix --experimental-features "nix-command flakes" flake show "${SCRIPT_DIR}" 2>/dev/null | grep -q "$system_choice"; then
        log_warn "Could not verify flake configuration for '${system_choice}'. Proceeding anyway..."
    fi

    disk_warning

    if ! confirm "Are you absolutely sure you want to continue?"; then
        log_info "Installation cancelled."
        exit 0
    fi

    # Step 1: Partition and format disks with disko
    log_info "Step 1/4: Partitioning disks with disko..."
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
        --mode disko "$disko_config"
    log_success "Disk partitioning complete!"

    # Step 2: Install NixOS
    log_info "Step 2/4: Installing NixOS..."
    sudo nixos-install --no-root-passwd --root /mnt --flake "${SCRIPT_DIR}#${system_choice}"
    log_success "NixOS installation complete!"

    # Step 3: Copy dotfiles to new system
    log_info "Step 3/4: Copying dotfiles to new system..."
    local target_dotfiles="/mnt/home/${user_choice}/.dotfiles"
    sudo mkdir -p "/mnt/home/${user_choice}"
    sudo cp -r "${SCRIPT_DIR}" "$target_dotfiles"
    sudo chown -R 1000:100 "/mnt/home/${user_choice}"  # UID 1000 is typically the first user
    log_success "Dotfiles copied!"

    # Step 4: Run home-manager inside the new system via nixos-enter
    log_info "Step 4/4: Setting up home-manager..."

    # Create a temporary script to run inside the installed system
    local hm_script="/mnt/tmp/setup-home-manager.sh"
    sudo tee "$hm_script" > /dev/null << EOF
#!/usr/bin/env bash
set -euo pipefail

export HOME="/home/${user_choice}"
export USER="${user_choice}"
cd "\$HOME/.dotfiles"

# Run home-manager switch as the user
sudo -u ${user_choice} nix --experimental-features "nix-command flakes" run home-manager -- \
    switch --flake "\$HOME/.dotfiles#${user_choice}"

# Set git remote
cd "\$HOME/.dotfiles"
sudo -u ${user_choice} git remote set-url origin git@github.com:Quil180/nixos-config || true

echo "Home-manager setup complete!"
EOF
    sudo chmod +x "$hm_script"

    # Execute the script in the installed system
    sudo nixos-enter --root /mnt -- /tmp/setup-home-manager.sh || {
        log_warn "Home-manager setup during install had issues. You may need to run 'home-manager switch' after first boot."
    }

    # Cleanup
    sudo rm -f "$hm_script"

    echo ""
    log_success "🎉 Installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Reboot into your new system: sudo reboot"
    echo "  2. Log in as '${user_choice}'"
    echo "  3. If home-manager didn't fully apply, run:"
    echo "     home-manager switch --flake ~/.dotfiles#${user_choice}"
    echo ""
}

# Post-install setup (for running after first boot if needed)
post_install() {
    log_info "Running post-installation setup..."

    local user_choice
    user_choice=$(prompt_with_default "What user am I" "$DEFAULT_USER")

    # Connect to WiFi if needed
    if confirm "Do you need to connect to WiFi?"; then
        local wifi_name
        local wifi_pass

        read -rp "WiFi network name: " wifi_name
        read -rsp "WiFi password: " wifi_pass
        echo ""

        if nmcli device wifi connect "$wifi_name" password "$wifi_pass"; then
            log_success "Connected to WiFi!"
        else
            log_error "Failed to connect to WiFi. Please connect manually."
        fi
    fi

    # Run home-manager switch
    log_info "Running home-manager switch..."
    nix --experimental-features "nix-command flakes" run home-manager -- \
        switch --flake "${HOME}/.dotfiles#${user_choice}"

    # Set git remote
    log_info "Setting git remote..."
    cd "${HOME}/.dotfiles"
    git remote set-url origin git@github.com:Quil180/nixos-config || true

    log_success "Post-installation setup complete!"
    log_info "You may want to run: source ~/.zshrc"
}

# Rebuild existing system
rebuild_system() {
    log_info "Rebuilding NixOS system..."

    local system_choice
    system_choice=$(prompt_with_default "Which system configuration" "$DEFAULT_SYSTEM")

    sudo nixos-rebuild switch --flake "${SCRIPT_DIR}#${system_choice}"
    log_success "System rebuild complete!"
}

# Rebuild home-manager
rebuild_home() {
    log_info "Rebuilding home-manager configuration..."

    local user_choice
    user_choice=$(prompt_with_default "Which user configuration" "$DEFAULT_USER")

    home-manager switch --flake "${SCRIPT_DIR}#${user_choice}"
    log_success "Home-manager rebuild complete!"
}

# Update flake inputs
update_flake() {
    log_info "Updating flake inputs..."
    nix flake update --flake "${SCRIPT_DIR}"
    log_success "Flake inputs updated!"
}

# Main menu
show_menu() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║       NixOS Configuration Manager            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    echo "  1) Fresh Install (from live ISO)"
    echo "  2) Post-Install Setup (after first boot)"
    echo "  3) Rebuild System (nixos-rebuild)"
    echo "  4) Rebuild Home (home-manager)"
    echo "  5) Update Flake Inputs"
    echo "  6) Exit"
    echo ""
}

# Wait for user to press enter before returning to menu
pause() {
    echo ""
    read -rp "Press Enter to continue..."
}

main() {
    check_root

    # If running from live ISO with no args, suggest fresh install
    if is_live_iso && [[ $# -eq 0 ]]; then
        log_info "Detected live ISO environment."
        if confirm "Would you like to perform a fresh install?"; then
            fresh_install
            exit 0
        fi
    fi

    # Handle command line arguments
    case "${1:-}" in
        install|fresh)
            fresh_install
            exit 0
            ;;
        post|setup)
            post_install
            exit 0
            ;;
        system|rebuild)
            rebuild_system
            exit 0
            ;;
        home)
            rebuild_home
            exit 0
            ;;
        update)
            update_flake
            exit 0
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  install, fresh  - Fresh install from live ISO"
            echo "  post, setup     - Post-install setup after first boot"
            echo "  system, rebuild - Rebuild NixOS system"
            echo "  home            - Rebuild home-manager"
            echo "  update          - Update flake inputs"
            echo "  help            - Show this help message"
            echo ""
            echo "If no command is given, an interactive menu is shown."
            exit 0
            ;;
    esac

    # Interactive menu
    while true; do
        show_menu
        read -rp "Select an option [1-6]: " choice

        case $choice in
            1) fresh_install; pause ;;
            2) post_install; pause ;;
            3) rebuild_system; pause ;;
            4) rebuild_home; pause ;;
            5) update_flake; pause ;;
            6)
                clear
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please select 1-6."
                pause
                ;;
        esac
    done
}

main "$@"
