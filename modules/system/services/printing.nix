{ config, lib, ... }:

let
  cfg = config.mySystem.services.printing;
in
{
  options.mySystem.services.printing.enable = lib.mkEnableOption "printing support";

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;
  };
}
