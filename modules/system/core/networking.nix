{ config, lib, ... }:

let
  cfg = config.mySystem.core.networking;
in
{
  options.mySystem.core.networking.enable = lib.mkEnableOption "networking defaults";

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      firewall.checkReversePath = false;
    };
  };
}
