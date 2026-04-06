{ username, ... }:
{
  # SSH Hardening
  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      # Only allow the primary user to SSH in if needed
      AllowUsers = [ username ];
    };
  };

  # Sudo Hardening
  security.sudo = {
    enable = true;
    execWheelOnly = true; # Only allow members of wheel to execute sudo
    extraConfig = ''
      # Require password for all sudo operations
      Defaults env_reset,timestamp_timeout=5
    '';
  };

  # Nix Hardening
  nix.settings = {
    # Only allow the primary user and root to use the nix-daemon
    allowed-users = [ "root" username ];
    trusted-users = [ "root" username ];
  };

  # Kernel Hardening (Basic)
  boot.kernel.sysctl = {
    # Restrict dmesg to root
    "kernel.dmesg_restrict" = 1;
    # Restrict ptrace to same-user processes
    "kernel.yama.ptrace_scope" = 1;
    # Hide kernel pointers in /proc and elsewhere
    "kernel.kptr_restrict" = 1;
    # Improve ASLR for mmap
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  # Restrict some namespaces if not needed (can break some apps like Chrome)
  # boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 0;
}
