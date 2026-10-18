#!/usr/bin/env bash
# NixOS Configuration Manager — maintenance helpers.
#
# Fresh installs (from a live ISO) now live in `nixos-install-drive`:
#   nix run github:Quil180/nixos-config#install -- --host <host>
# or on the bundled installer ISO, just run `nixos-install-drive --host <host>`.
# This script keeps the day-to-day maintenance commands for an installed
# machine: rebuild system, rebuild home, update flake inputs, and a small
# set of shared helpers (logging, confirmation, checkpoints).

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

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
# Check if running as root (maintenance is run as the user, sudo when needed)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
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

# Wait for user to press enter
pause() {
    echo ""
    read -rp "Press Enter to continue..."
}

# ---------------------------------------------------------------------------
# Maintenance commands
# ---------------------------------------------------------------------------
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

    local system_choice
    local user_choice

    system_choice=$(prompt_with_default "Which system configuration" "$DEFAULT_SYSTEM")
    user_choice=$(prompt_with_default "Which user configuration" "$DEFAULT_USER")

    # integratedHome hosts (e.g. snowflake) have no standalone target.
    if [[ $(nix eval "${SCRIPT_DIR}#homeConfigurations" --apply "h: h ? \"${user_choice}@${system_choice}\"" 2>/dev/null) != "true" ]]; then
        log_error "No standalone home target '${user_choice}@${system_choice}'. If home-manager is integrated into that host, rebuild the system instead."
        return 1
    fi

    home-manager switch --flake "${SCRIPT_DIR}#${user_choice}@${system_choice}"
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
    echo "  1) Rebuild System (nixos-rebuild)"
    echo "  2) Rebuild Home (home-manager)"
    echo "  3) Update Flake Inputs"
    echo "  4) Exit"
    echo ""
    log_info "Fresh installs? Use 'nixos-install-drive --host <host>' (or"
    log_info "  'nix run .#install -- --host <host>') from the installer ISO."
}

main() {
    check_root

    case "${1:-}" in
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
            echo "  system, rebuild - Rebuild NixOS system"
            echo "  home            - Rebuild home-manager"
            echo "  update          - Update flake inputs"
            echo "  help            - Show this help message"
            echo ""
            echo "Fresh installs are handled by 'nixos-install-drive --host <host>'."
            echo "If no command is given, an interactive menu is shown."
            exit 0
            ;;
    esac

    # Interactive menu
    while true; do
        show_menu
        read -rp "Select an option [1-4]: " choice

        case $choice in
            1) rebuild_system; pause ;;
            2) rebuild_home || true; pause ;;
            3) update_flake; pause ;;
            4)
                clear
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please select 1-4."
                pause
                ;;
        esac
    done
}

main "$@"