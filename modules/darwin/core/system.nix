{ config, lib, ... }:

let
  cfg = config.myDarwin.core.system;
in
{
  options.myDarwin.core.system.enable = lib.mkEnableOption "macOS system defaults";

  config = lib.mkIf cfg.enable {
    system = {
      primaryUser = "yurikon";
      stateVersion = 6;

      defaults = {
        NSGlobalDomain = {
          ApplePressAndHoldEnabled = false;
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
        };
      };
    };
  };
}
