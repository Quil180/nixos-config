{config, pkgs, inputs, ...}:

let
  dotfiles="~/.dotfiles";
in
  {
  # shell config
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
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

      push() {
        git add .
        git commit .
        git push origin HEAD:$1
      }
    '';
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}
