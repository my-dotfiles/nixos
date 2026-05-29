{ config, lib, ... }:

let
  cfg = config.mySystem.services.jellyfin;
in
{
  options.mySystem.services.jellyfin.enable = lib.mkEnableOption "Jellyfin media server";

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
