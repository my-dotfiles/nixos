{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.services.docker;
in
{
  options.mySystem.services.docker.enable = lib.mkEnableOption "Docker container runtime";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    virtualisation.oci-containers.backend = "docker";

    users.users.yurikon.extraGroups = [
      "docker"
    ];

    environment.systemPackages = with pkgs; [
      docker-compose
      lazydocker
    ];
  };
}
