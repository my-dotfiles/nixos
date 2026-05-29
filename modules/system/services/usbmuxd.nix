{ config, lib, ... }:

let
  cfg = config.mySystem.services.usbmuxd;
in
{
  options.mySystem.services.usbmuxd.enable = lib.mkEnableOption "iPhone and iPad USB pairing support";

  config = lib.mkIf cfg.enable {
    services.usbmuxd.enable = true;
  };
}
