{config, ...}: let
  dotfiles = "~/.dotfiles";
in {
  # shell config
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["\\eOA"];
      searchDownKey = ["\\eOB"];
    };
    oh-my-zsh = {
      enable = true;
      theme = "risto";
      plugins = [
        "git"
        "history"
      ];
    };

    shellAliases = {
      # replacing cd with zoxide
      cd = "z";
      # update aliases
      updh = "home-manager switch --flake ${dotfiles}";
      updf = "cd ${dotfiles} && nix flake update";
      upds = "sudo nixos-rebuild switch --flake ${dotfiles}";
      updb = "source ~/.zshrc";
      upda = "updf && upds && updh && updb";
      # clean nix store
      clean = "nix-store --gc";
      optimize = "nix-store --optimise";
      # updatetime and updatelog
      updatetime = "systemctl status nixos-upgrade.timer";
      updatelog = "systemctl status nixos-upgrade.service";

      # general useful aliases
      vivado = "nix run gitlab:doronbehar/nix-xilinx#vivado";
      nf = "fastfetch";

      # g14 related aliases
      gpu = "supergfxctl -g";
      hybrid = "supergfxctl -m Hybrid && wayland-logout";
      integrated = "supergfxctl -m Integrated && wayland-logout";
      vfio = "supergfxctl -m Vfio";
      dedicated = "supergfxctl -m AsusMuxDgpu && sudo reboot now";
    };
    initExtra = ''
       runa() {
         temp=""
         for arg in "$@"
         do
           temp+="$arg "
         done
         nasm -felf64 $temp -o a.o
         ld a.o -o a
         ./a
         rm a.o
         rm a
       }

       debugc() {
         temp=""
         for arg in "$@"
         do
           temp+="$arg "
         done
         gcc $temp -g -O0
         valgrind --track-origins=yes --leak-check=full --show-leak-kinds=all ./a.out
         rm a.out
         rm vgcore.*
       }

       runc() {
         temp=""
         for arg in "$@"
         do
           temp+="$arg "
         done
         gcc $temp
         ./a.out
         rm a.out
       }

       runcpp() {
         temp=""
         for arg in "$A"
         do
           temp+="$arg "
         done
         g++ $temp -o a.out -g
         ./a.out
         rm a.out
       }

       runj() {
         temp=""
         for arg in "$@"
         do
           temp+="$arg "
         done
         java $temp
       }

       test() {
         nix-shell -p $@
       }
    '';
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}
