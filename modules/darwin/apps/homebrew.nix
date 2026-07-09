{ config, lib, ... }:

let
  cfg = config.myDarwin.apps.homebrew;

  emacsPlusTap = [
    {
      name = "d12frosted/emacs-plus";
      trusted = true;
    }
  ];

  legacyEmacsTaps = [
    {
      name = "railwaycat/emacsmacport";
      trusted = true;
    }
  ];

  emacsFormulae = [
    "emacs-plus@30"
  ];

  # Keep only fast-moving or ecosystem-managed CLI tools in Homebrew. General
  # terminal utilities and language tools should live in Home Manager/Nix.
  formulae = [
    "uv"
    "yarn"
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
  ];

  systemCasks = [
    "macfuse"
    "tailscale-app"
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
      description = "Keep the small Homebrew formula set used for fast-moving tools.";
    };

    includeLegacyEmacsTaps = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Keep legacy Emacs Homebrew taps declared while comparing macOS-specific Emacs variants.";
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

      taps = emacsPlusTap ++ lib.optionals cfg.includeLegacyEmacsTaps legacyEmacsTaps;
      brews = emacsFormulae ++ lib.optionals cfg.includeFormulae formulae;
      casks = guiCasks ++ fontCasks ++ systemCasks;
      masApps = { };
    };
  };
}
