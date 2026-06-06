{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.services.rclone;
  mountBase = "${config.home.homeDirectory}/cloud";
  configFile = "${config.xdg.configHome}/rclone/rclone.conf";
  cacheDir = "${config.xdg.cacheHome}/rclone";

  mounts = [
    {
      name = "gdrive";
      remote = "gdrive:";
      mountPoint = "${mountBase}/gdrive";
    }
    {
      name = "onedrive";
      remote = "onedrive:";
      mountPoint = "${mountBase}/onedrive";
    }
  ];

  mkMountService =
    mount:
    lib.nameValuePair "rclone-${mount.name}" {
      Unit = {
        Description = "rclone mount for ${mount.name}";
        Documentation = "man:rclone(1)";
        ConditionPathExists = configFile;
      };

      Service = {
        Type = "simple";
        Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.fuse3 ]}";
        ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${mount.mountPoint}";
        ExecStart = ''
          ${lib.getExe pkgs.rclone} mount ${mount.remote} ${mount.mountPoint} \
            --config ${configFile} \
            --cache-dir ${cacheDir} \
            --vfs-cache-mode writes \
            --dir-cache-time 72h \
            --poll-interval 1m \
            --contimeout 5s \
            --timeout 15s \
            --retries 1 \
            --low-level-retries 1
        '';
        ExecStop = "-/run/wrappers/bin/fusermount3 -uz ${mount.mountPoint}";
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStopSec = "30s";
      };

      Install.WantedBy = lib.optional cfg.autoStart "default.target";
    };
in
{
  options.myHome.services.rclone = {
    enable = lib.mkEnableOption "rclone cloud storage mounts";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Automatically start rclone FUSE mounts at login. Leave disabled to avoid
        file managers blocking while probing unavailable remote mounts.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rclone
      fuse3
    ];

    systemd.user.services = lib.listToAttrs (map mkMountService mounts);
  };
}
