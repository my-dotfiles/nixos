{ config, lib, ... }:

let
  cfg = config.mySystem.services.scanning;
in
{
  options.mySystem.services.scanning.enable = lib.mkEnableOption "document scanner support";

  config = lib.mkIf cfg.enable {
    hardware.sane.enable = true;
  };
}
