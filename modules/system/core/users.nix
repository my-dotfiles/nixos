{ config, lib, ... }:

let
  cfg = config.mySystem.core.users;
in
{
  options.mySystem.core.users.enable = lib.mkEnableOption "local user accounts";

  config = lib.mkIf cfg.enable {
    users.users.yurikon = {
      isNormalUser = true;
      description = "yurikon";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
