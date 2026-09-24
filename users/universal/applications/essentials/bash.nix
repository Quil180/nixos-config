{ lib, ... }:
{
  flake.homeModules.bash =
    { config, tags, ... }:
    let
      dotfiles = "${config.home.homeDirectory}/.dotfiles";
    in
    {
      # shell config
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        dotDir = "${config.home.homeDirectory}/.config/zsh";
        historySubstringSearch = {
          enable = true;
          searchUpKey = [ "\\eOA" ];
          searchDownKey = [ "\\eOB" ];
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
          updh = "home-manager switch --flake ${dotfiles} -b backup";
          updf = "cd ${dotfiles} && nix flake update --flake ${dotfiles}";
          upds = "sudo nixos-rebuild switch --flake ${dotfiles}";
          updb = "source ~/.config/zsh/.zshrc";
          upda = "updf && upds && updh && updb";
          # clean nix store
          clean = "nix-store --gc";
          optimize = "nix-store --optimise";
          # wifi reset full (drivers)
          restartwifi = "sudo modprobe -r mt7921e && sudo modprobe mt7921e";
          hibernate = "sudo systemctl hibernate";
          suspend = "sudo systemctl suspend";

          # NixOS configuration manager
          polaris = "${dotfiles}/install.sh";

          # general useful aliases
          vivado = "nix run gitlab:doronbehar/nix-xilinx#vivado";
          nf = "fastfetch";
          g = "git";
          vlsi = "export TERM=ansi; ssh -Y yo485591@vlsi.eecs.ucf.edu";
        }
        // lib.optionalAttrs (builtins.elem "asus" tags) {
          # g14/ASUS-only: GPU mode switching is cardwire's job (system-side
          # `cardwire` module). It blocks device nodes instead of unbinding PCI, so
          # no logout is needed; MUX stays asusctl's (kernel: 0 = dGPU-only,
          # 1 = optimus/hybrid) and wants a reboot.
          gpu = "cardwire get";
          hybrid = "cardwire set hybrid";
          integrated = "cardwire set integrated";
          smart = "cardwire set smart";
          dedicated = "asusctl armoury set gpu_mux_mode 0 && sudo reboot now";
        };
        initContent = ''
          if [ -f "$HOME/.cache/terminal/sequences" ]; then
            cat "$HOME/.cache/terminal/sequences"
          fi

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
            for arg in "$@"
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

          # Not `test`: that would shadow the shell builtin for every script and
          # plugin sourced into this shell.
          try() {
            nix-shell -p $@
          }
        '';
        history = {
          size = 10000;
          path = "${config.xdg.dataHome}/zsh/history";
        };
      };
    };
}
