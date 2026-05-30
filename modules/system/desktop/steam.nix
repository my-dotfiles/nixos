{ config, lib, ... }:

let
  cfg = config.mySystem.desktop.steam;
in
{
  options.mySystem.desktop.steam.enable = lib.mkEnableOption "Steam gaming platform";

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.gamemode.enable = true;
  };
}
