{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.terminal;
  optionalPkg =
    path:
    let
      value = lib.attrByPath path null pkgs;
    in
    lib.optional (value != null && lib.meta.availableOn pkgs.stdenv.hostPlatform value) value;
in
{
  options.myHome.cli.terminal.enable = lib.mkEnableOption "terminal utilities and shell integrations";

  config = lib.mkIf cfg.enable {
    home.packages = lib.concatMap optionalPkg [
      [ "ripgrep" ]
      [ "bubblewrap" ]
      [ "socat" ]
      [ "fd" ]
      [ "bat" ]
      [ "eza" ]
      [ "fzf" ]
      [ "jq" ]
      [ "fastfetch" ]
      [ "tree" ]
      [ "unzip" ]
      [ "file" ]
      [ "curl" ]
      [ "wget" ]
      [ "rsync" ]
      [ "aria2" ]
      [ "ghostscript" ]
      [ "git-lfs" ]
      [ "imagemagick" ]
      [ "img2pdf" ]
      [ "librsvg" ]
      [ "libvterm" ]
      [ "mosh" ]
      [ "mpv" ]
      [ "neovim" ]
      [ "poppler" ]
      [ "_7zz" ]
      [ "tig" ]
      [ "unar" ]
      [ "ncdu" ]
      [ "dust" ]
      [ "tokei" ]
      [ "cloc" ]
      [ "mdcat" ]
      [ "pandoc" ]
    ];

    programs.bash = {
      shellAliases = {
        ls = "eza --icons=auto --group-directories-first";
        ll = "eza -l --icons=auto --group-directories-first";
        la = "eza -la --icons=auto --group-directories-first";
        cat = "bat --style=plain --paging=never";
        ".." = "cd ..";
        "..." = "cd ../..";
        c = "clear";
        g = "git";
        e = "emacsclient -n -c -a emacs";
        et = "emacsclient -t -a emacs";
        hmconfig = "$EDITOR ~/nixos-config-macos/home.nix";
        reload = "source ~/.bashrc";
      };

      bashrcExtra = ''
        function y() {
          local tmp cwd
          tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          command yazi "$@" --cwd-file="$tmp"
          cwd="$(cat "$tmp")"
          [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      options = [ "--cmd j" ];
    };

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
