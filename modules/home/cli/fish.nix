{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.fish;
in
{
  options.myHome.cli.fish = {
    enable = lib.mkEnableOption "Fish shell configuration";

    setSessionShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set SHELL in the Home Manager session to the managed fish binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;

      shellAliases = {
        ls = "eza --icons=auto --group-directories-first";
        ll = "eza -l --icons=auto --group-directories-first";
        la = "eza -la --icons=auto --group-directories-first";
        cat = "bat --style=plain --paging=never";
        ".." = "cd ..";
        "..." = "cd ../..";
        c = "clear";
        g = "git";
        e = "emacsclient -c -a emacs";
        et = "emacsclient -t";
        hmconfig = "$EDITOR ~/nixos-config/home.nix";
      };

      interactiveShellInit = ''
        set fish_greeting
        fish_add_path $HOME/.nix-profile/bin
        fish_add_path $HOME/.local/state/nix/profile/bin
        fish_add_path $HOME/.local/bin
        fish_add_path $HOME/.cargo/bin
        fish_add_path $HOME/.npm-global/bin

        function y
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          command yazi $argv --cwd-file="$tmp"
          set cwd (cat "$tmp")
          if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
            cd "$cwd"
          end
          rm -f -- "$tmp"
        end
      '';
    };

    home.packages = [
      pkgs.fish
    ];

    home.sessionVariables = lib.mkIf cfg.setSessionShell {
      SHELL = "${pkgs.fish}/bin/fish";
    };
  };
}
