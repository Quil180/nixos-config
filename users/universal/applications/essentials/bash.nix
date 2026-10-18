_: {
  flake.homeModules.bash =
    { config, ... }:
    {
      # zsh history.
      persist.directories = [ ".local/share/zsh" ];

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
          # clean nix store
          clean = "nix-store --gc";
          optimize = "nix-store --optimise";
          # wifi reset full (drivers)
          restartwifi = "sudo modprobe -r mt7921e && sudo modprobe mt7921e";
          hibernate = "sudo systemctl hibernate";
          suspend = "sudo systemctl suspend";

          # general useful aliases
          nf = "fastfetch";
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
