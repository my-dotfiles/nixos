{ config, lib, ... }:

let
  cfg = config.mySystem.services.tailscale;
in
{
  options.mySystem.services.tailscale.enable = lib.mkEnableOption "Tailscale mesh VPN";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}
