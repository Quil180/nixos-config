#!/usr/bin/env bash
# NixOS Installation Script
# This script installs NixOS with home-manager in a single phase
#
# CHANGES vs original:
#   - network_setup(): checks/establishes connectivity before touching disks
#   - submodule init after copying dotfiles (wallpapers etc.)
#   - checkpoint file so a failed run can resume instead of starting over
#   - post-disko pause to rekey agenix secrets against the new host key
#   - basic flake-reachability sanity check before the destructive step

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
# NOTE: must survive the storage-bypass step, which bind-mounts /mnt/tmp onto
# /tmp (root-owned) partway through the run — so this can't live under /tmp
# or /mnt. $HOME is untouched by that bind-mount.
CHECKPOINT_FILE="${HOME}/.nixos_install_checkpoint"

# ---------------------------------------------------------------------------
# Checkpointing helpers
# ---------------------------------------------------------------------------
checkpoint_mark() {
    mkdir -p "$(dirname "$CHECKPOINT_FILE")" 2>/dev/null || true
    echo "$1" >> "$CHECKPOINT_FILE" 2>/dev/null || true
}

checkpoint_done() {
    [[ -f "$CHECKPOINT_FILE" ]] && grep -qx "$1" "$CHECKPOINT_FILE" 2>/dev/null
}

checkpoint_reset() {
    rm -f "$CHECKPOINT_FILE" 2>/dev/null || true
}

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

# ---------------------------------------------------------------------------
# Network setup — run BEFORE anything disk/flake related
# ---------------------------------------------------------------------------
network_setup() {
    if checkpoint_done "network_setup"; then
        log_info "Network already confirmed (checkpoint). Skipping."
        return 0
    fi

    log_info "Checking network connectivity..."
    if curl -s --max-time 5 https://cache.nixos.org > /dev/null 2>&1; then
        log_success "Already online."
        checkpoint_mark "network_setup"
        return 0
    fi

    log_warn "No connectivity detected."
    if ! command -v nmcli &>/dev/null; then
        log_error "nmcli not found. Connect to the network manually, then re-run this script."
        exit 1
    fi

    if confirm "Connect to Wi-Fi now?"; then
        local wifi_name wifi_pass
        read -rp "WiFi network name (SSID): " wifi_name
        read -rsp "WiFi password: " wifi_pass
        echo ""
        if nmcli device wifi connect "$wifi_name" password "$wifi_pass"; then
            log_success "Connected to WiFi!"
        else
            log_error "Failed to connect. Connect manually (nmcli, or ethernet) then re-run."
            exit 1
        fi
    else
        log_warn "Proceeding without confirming connectivity — flake fetch may fail."
    fi

    # Re-check
    if curl -s --max-time 5 https://cache.nixos.org > /dev/null 2>&1; then
        checkpoint_mark "network_setup"
    else
        log_error "Still no connectivity. Fix networking and re-run the script."
        exit 1
    fi
}

# Sanity-check the flake is actually fetchable/evaluable before we destroy disks
flake_sanity_check() {
    local system_choice="$1"

    if checkpoint_done "flake_sanity_check"; then
        log_info "Flake already validated (checkpoint). Skipping."
        return 0
    fi

    log_info "Validating flake evaluates cleanly for '${system_choice}'..."
    if ! nix --experimental-features "nix-command flakes" eval \
        "${SCRIPT_DIR}#nixosConfigurations.${system_choice}.config.system.build.toplevel.drvPath" \
        > /dev/null 2>&1; then
        log_error "Flake failed to evaluate for '${system_choice}'. Fix errors before wiping disks."
        exit 1
    fi
    log_success "Flake evaluates cleanly."
    checkpoint_mark "flake_sanity_check"
}

# ---------------------------------------------------------------------------
# Fresh install from live ISO
# ---------------------------------------------------------------------------
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

    network_setup
    flake_sanity_check "$system_choice"

    if ! checkpoint_done "disko_done"; then
        disk_warning
        if ! confirm "Are you absolutely sure you want to continue?"; then
            log_info "Installation cancelled."
            exit 0
        fi

        # Step 1: Partition and format disks with disko
        log_info "Step 1/5: Partitioning disks with disko..."
        sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
            --mode disko --flake "${SCRIPT_DIR}#${system_choice}"
        log_success "Disk partitioning complete!"
        checkpoint_mark "disko_done"
    else
        log_info "Disko already run (checkpoint). Skipping partitioning — assuming /mnt is already mounted."
    fi

    if ! checkpoint_done "storage_bypass_done"; then
        # --- STORAGE BYPASS: mapping live storage to the physical disk ---
        log_info "Bypassing RAM limits by mapping live storage to the physical disk..."
        sudo mkdir -p /mnt/tmp
        sudo mount --bind /mnt/tmp /tmp
        sudo mkdir -p /mnt/nix-overlay/upper
        sudo mkdir -p /mnt/nix-overlay/work
        sudo mount -t overlay overlay -o lowerdir=/nix/store,upperdir=/mnt/nix-overlay/upper,workdir=/mnt/nix-overlay/work /nix/store
        sudo systemctl restart nix-daemon
        sleep 3 # Give the daemon a second to catch up
        checkpoint_mark "storage_bypass_done"
    fi

    if ! checkpoint_done "nixos_install_done"; then
        # Step 2: Install NixOS
        log_info "Step 2/5: Installing NixOS..."

        # 1. Build the system closure locally to bypass the /mnt gitTracked bug
        nix --experimental-features "nix-command flakes" build "${SCRIPT_DIR}#nixosConfigurations.${system_choice}.config.system.build.toplevel"

        # 2. Install the pre-built closure
        sudo nixos-install --no-root-passwd --root /mnt --system ./result
        log_success "NixOS installation complete!"
        checkpoint_mark "nixos_install_done"
    else
        log_info "NixOS already installed (checkpoint). Skipping."
    fi

    # --- AGENIX REKEY REMINDER ---
    # secrets/secrets.nix hardcodes the host's SSH pubkey. A freshly installed
    # machine has a BRAND NEW host key, so existing secrets/*.age files will
    # NOT decrypt until they're re-encrypted against it.
    if ! checkpoint_done "agenix_rekey_ack"; then
        local new_host_key
        new_host_key=$(sudo cat /mnt/etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || echo "")
        echo ""
        log_warn "=============================================================="
        log_warn " AGENIX REKEY REQUIRED"
        log_warn "=============================================================="
        if [[ -n "$new_host_key" ]]; then
            echo "  New host public key:"
            echo "    $new_host_key"
        else
            echo "  Could not read /mnt/etc/ssh/ssh_host_ed25519_key.pub yet."
            echo "  (It may not be generated until first boot with sshd enabled.)"
        fi
        echo ""
        echo "  Update secrets/secrets.nix with this key for '${system_choice}',"
        echo "  then from your dev machine (or after first boot) run:"
        echo "    cd ${SCRIPT_DIR} && agenix rekey"
        echo ""
        echo "  Until you do this, encrypted secrets (git identity, snowflake"
        echo "  secret, etc.) will fail to decrypt on the new system."
        log_warn "=============================================================="
        echo ""
        if confirm "Have you noted this and will handle the rekey?"; then
            checkpoint_mark "agenix_rekey_ack"
        fi
    fi

    if ! checkpoint_done "dotfiles_copied"; then
        # Step 3: Copy dotfiles to new system
        log_info "Step 3/5: Copying dotfiles to new system..."
        local target_dotfiles="/mnt/home/${user_choice}/.dotfiles"
        sudo mkdir -p "/mnt/home/${user_choice}"
        sudo cp -r "${SCRIPT_DIR}" "$target_dotfiles"
        sudo chown -R 1000:100 "/mnt/home/${user_choice}"  # UID 1000 is typically the first user
        log_success "Dotfiles copied!"

        # Init submodules (wallpapers) inside the copied checkout
        log_info "Initializing git submodules (wallpapers, etc.)..."
        if sudo -u "#1000" git -C "$target_dotfiles" submodule update --init --recursive 2>/dev/null; then
            log_success "Submodules initialized."
        else
            log_warn "Submodule init failed or requires auth (SSH key not yet on new system)."
            log_warn "Run 'git submodule update --init --recursive' manually after first login."
        fi

        checkpoint_mark "dotfiles_copied"
    else
        log_info "Dotfiles already copied (checkpoint). Skipping."
    fi

    if ! checkpoint_done "home_manager_done"; then
        # Step 4: Run home-manager inside the new system via nixos-enter
        log_info "Step 4/5: Setting up home-manager..."

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
        if sudo nixos-enter --root /mnt -- /tmp/setup-home-manager.sh; then
            checkpoint_mark "home_manager_done"
        else
            log_warn "Home-manager setup during install had issues. You may need to run 'home-manager switch' after first boot."
        fi

        # Cleanup
        sudo rm -f "$hm_script"
    else
        log_info "Home-manager already configured (checkpoint). Skipping."
    fi

    log_info "Step 5/5: Final checks..."
    echo ""
    log_success "🎉 Installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Reboot into your new system: sudo reboot"
    echo "  2. Log in as '${user_choice}'"
    echo "  3. If secrets don't decrypt, rekey agenix (see reminder above)"
    echo "  4. If submodules didn't init, run:"
    echo "     git -C ~/.dotfiles submodule update --init --recursive"
    echo "  5. If home-manager didn't fully apply, run:"
    echo "     home-manager switch --flake ~/.dotfiles#${user_choice}"
    echo ""

    checkpoint_reset
}

# Post-install setup (for running after first boot if needed)
post_install() {
    log_info "Running post-installation setup..."

    local user_choice
    user_choice=$(prompt_with_default "What user am I" "$DEFAULT_USER")

    network_setup

    # Init submodules in case they weren't handled during fresh_install
    if [[ -d "${SCRIPT_DIR}/.git" ]]; then
        log_info "Ensuring git submodules are initialized..."
        git -C "${SCRIPT_DIR}" submodule update --init --recursive || \
            log_warn "Submodule init failed — check SSH access to git@github.com."
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

# Reset a partial/failed install so fresh_install starts over from scratch
reset_install_state() {
    if confirm "This clears the install checkpoint file (does NOT touch disks). Continue?"; then
        checkpoint_reset
        log_success "Checkpoint cleared. Next 'fresh_install' run starts from the beginning."
    fi
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
    echo "  6) Reset Install Checkpoint (after a failed run)"
    echo "  7) Exit"
    echo ""
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        log_warn "A previous install run left a checkpoint file — 'Fresh Install' will resume, not restart."
    fi
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
        reset)
            reset_install_state
            exit 0
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  install, fresh  - Fresh install from live ISO (resumable)"
            echo "  post, setup     - Post-install setup after first boot"
            echo "  system, rebuild - Rebuild NixOS system"
            echo "  home            - Rebuild home-manager"
            echo "  update          - Update flake inputs"
            echo "  reset           - Clear install checkpoint (after a failed run)"
            echo "  help            - Show this help message"
            echo ""
            echo "If no command is given, an interactive menu is shown."
            exit 0
            ;;
    esac

    # Interactive menu
    while true; do
        show_menu
        read -rp "Select an option [1-7]: " choice

        case $choice in
            1) fresh_install; pause ;;
            2) post_install; pause ;;
            3) rebuild_system; pause ;;
            4) rebuild_home; pause ;;
            5) update_flake; pause ;;
            6) reset_install_state; pause ;;
            7)
                clear
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please select 1-7."
                pause
                ;;
        esac
    done
}

main "$@"
