{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.services.tinymediamanager;
in
{
  options.mySystem.services.tinymediamanager = {
    enable = lib.mkEnableOption "tinyMediaManager Docker container";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/tinymediamanager";
      description = "Host directory for tinyMediaManager configuration and state.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/media";
      description = "Host media library directory exposed to tinyMediaManager.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "Localhost port for the tinyMediaManager web UI.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.tinymediamanager = {
      image = "tinymediamanager/tinymediamanager:latest";
      autoStart = false;
      ports = [
        "127.0.0.1:${toString cfg.port}:4000"
      ];
      volumes = [
        "${cfg.dataDir}:/data"
        "${cfg.mediaDir}:/media"
      ];
      environment = {
        USER_ID = "1000";
        GROUP_ID = "100";
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        TZ = config.time.timeZone;
      };
    };
  };
}
