{ config, lib, ... }:

let
  cfg = config.myDarwin.apps.homebrew;
in
{
  options.myDarwin.apps.homebrew.enable = lib.mkEnableOption "Homebrew package management";

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      global.brewfile = true;

      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "none";
      };

      # Keep the current Homebrew inventory declared first. After the first
      # successful darwin-rebuild, migrate duplicate CLI tools to Home Manager
      # in smaller, easy-to-verify batches.
      taps = [
        "d12frosted/emacs-plus"
        "railwaycat/emacsmacport"
      ];

      brews = [
        "aria2"
        "bat"
        "cloc"
        "cmake"
        "direnv"
        "dust"
        "fastfetch"
        "fd"
        "fzf"
        "gh"
        "ghostscript"
        "git-lfs"
        "glow"
        "helix"
        "imagemagick"
        "img2pdf"
        "jdtls"
        "jq"
        "lazygit"
        "librsvg"
        "libvterm"
        "mdcat"
        "mosh"
        "mpv"
        "neovim"
        "pandoc"
        "poppler"
        "pyright"
        "ripgrep"
        "ruff"
        "rust"
        "sevenzip"
        "starship"
        "tailscale"
        "tig"
        "tmux"
        "unar"
        "uv"
        "wget"
        "yarn"
        "yazi"
        "zoxide"
      ];

      casks = [
        "drawio"
        "font-jetbrains-mono-nerd-font"
        "font-maple-mono"
        "font-maple-mono-nf"
        "font-maple-mono-nf-cn"
        "font-sarasa-gothic"
        "ghostty"
        "google-chrome"
        "libreoffice"
        "libreoffice-language-pack"
        "macfuse"
        "stats"
      ];
      masApps = { };
    };
  };
}
