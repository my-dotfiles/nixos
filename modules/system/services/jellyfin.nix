{ config, lib, ... }:

let
  cfg = config.mySystem.services.jellyfin;
in
{
  options.mySystem.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start Jellyfin automatically at boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Keep the server installed and configured without reserving hundreds of
    # MiB on a workstation that does not need it continuously.
    systemd.services.jellyfin.wantedBy = lib.mkIf (!cfg.autoStart) (lib.mkForce [ ]);
  };
}
