{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.steam;
in
{
  options.mySystem.desktop.steam.enable = lib.mkEnableOption "Steam gaming platform";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.protontricks ];

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraArgs = "-system-composer";
      };
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.gamemode.enable = true;
  };
}
