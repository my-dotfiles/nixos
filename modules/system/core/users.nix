{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.core.users;
in
{
  options.mySystem.core.users.enable = lib.mkEnableOption "local user accounts";

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;

    users.users.yurikon = {
      isNormalUser = true;
      description = "yurikon";
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
