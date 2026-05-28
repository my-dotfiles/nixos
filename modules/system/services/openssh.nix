{ config, lib, ... }:

let
  cfg = config.mySystem.services.openssh;
in
{
  options.mySystem.services.openssh.enable = lib.mkEnableOption "OpenSSH daemon";

  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;
  };
}
