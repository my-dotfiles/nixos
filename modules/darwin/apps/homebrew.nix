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

      taps = [ ];
      brews = [ ];
      casks = [ ];
      masApps = { };
    };
  };
}
