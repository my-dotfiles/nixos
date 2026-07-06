{ config, lib, ... }:

let
  cfg = config.myDarwin.apps.homebrew;

  legacyEmacsTaps = [
    {
      name = "d12frosted/emacs-plus";
      trusted = true;
    }
    {
      name = "railwaycat/emacsmacport";
      trusted = true;
    }
  ];

  # Formulae currently installed through Homebrew. Many of these now overlap
  # with Home Manager, but keeping them declared makes the first migration
  # phase boring and reversible.
  formulae = [
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

  guiCasks = [
    "drawio"
    "ghostty"
    "google-chrome"
    "libreoffice"
    "libreoffice-language-pack"
    "stats"
  ];

  fontCasks = [
    "font-jetbrains-mono-nerd-font"
    "font-maple-mono"
    "font-maple-mono-nf"
    "font-maple-mono-nf-cn"
    "font-sarasa-gothic"
  ];

  systemCasks = [
    "macfuse"
  ];
in
{
  options.myDarwin.apps.homebrew = {
    enable = lib.mkEnableOption "Homebrew package management";

    cleanupMode = lib.mkOption {
      type = lib.types.enum [
        "none"
        "check"
        "uninstall"
        "zap"
      ];
      default = "none";
      description = "How nix-darwin should handle Homebrew packages absent from the generated Brewfile.";
    };

    includeFormulae = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep the existing Homebrew formula inventory declared while CLI tools migrate to Nix.";
    };

    includeLegacyEmacsTaps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep legacy Emacs Homebrew taps declared until the Nix-managed Emacs setup has fully replaced them.";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      global = {
        brewfile = true;
        autoUpdate = false;
      };

      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = cfg.cleanupMode;
        extraEnv = {
          HOMEBREW_NO_ANALYTICS = "1";
          HOMEBREW_NO_ENV_HINTS = "1";
          HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
        };
      };

      caskArgs = {
        appdir = "/Applications";
        require_sha = false;
      };

      greedyCasks = false;

      taps = lib.optionals cfg.includeLegacyEmacsTaps legacyEmacsTaps;
      brews = lib.optionals cfg.includeFormulae formulae;
      casks = guiCasks ++ fontCasks ++ systemCasks;
      masApps = { };
    };
  };
}
