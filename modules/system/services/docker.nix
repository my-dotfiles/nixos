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
      daemon.settings = {
        proxies = {
          "http-proxy" = "http://127.0.0.1:7890";
          "https-proxy" = "http://127.0.0.1:7890";
          "no-proxy" = "localhost,127.0.0.1";
        };
      };
    };

    virtualisation.oci-containers.backend = "docker";

    systemd.services.docker.wantedBy = lib.mkForce [ ];
    systemd.sockets.docker.wantedBy = lib.mkForce [ ];

    users.users.yurikon.extraGroups = [
      "docker"
    ];

    environment.systemPackages = with pkgs; [
      docker-compose
      lazydocker
    ];
  };
}
