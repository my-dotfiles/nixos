{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.lockscreen;
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  swaylock = lib.getExe pkgs.swaylock-effects;
  wallpaperArgs = lib.escapeShellArgs cfg.wallpapers;
  lockScreen = pkgs.writeShellScriptBin "lock-screen" ''
    exec ${systemctl} --user start lock-screen.service
  '';
  runLockScreen = pkgs.writeShellScript "run-lock-screen" ''
    set -eu

    wallpapers=(${wallpaperArgs})
    existing_wallpapers=()

    for wallpaper in "''${wallpapers[@]}"; do
      if [ -f "$wallpaper" ]; then
        existing_wallpapers+=("$wallpaper")
      fi
    done

    swaylock_args=(
      --daemonize
      --ignore-empty-password
      --show-failed-attempts
      --font "Maple Mono NF CN"
      --font-size 28
      --indicator-radius 120
      --indicator-thickness 8
      --ring-color "7fc8ffcc"
      --ring-ver-color "c7ff7fcc"
      --ring-wrong-color "ff7f7fcc"
      --ring-clear-color "ffd37fcc"
      --key-hl-color "c7ff7fff"
      --bs-hl-color "ff7f7fff"
      --inside-color "111318aa"
      --inside-ver-color "111318aa"
      --inside-wrong-color "111318cc"
      --inside-clear-color "111318aa"
      --line-color "00000000"
      --separator-color "00000000"
      --text-color "e6edf3ff"
      --text-ver-color "e6edf3ff"
      --text-wrong-color "ffd6d6ff"
      --text-clear-color "e6edf3ff"
    )

    if [ "''${#existing_wallpapers[@]}" -gt 0 ]; then
      index="$(${pkgs.coreutils}/bin/shuf -i "0-$((''${#existing_wallpapers[@]} - 1))" -n 1)"
      swaylock_args+=(--image "''${existing_wallpapers[$index]}" --scaling fill)
    else
      swaylock_args+=(--color "111318")
    fi

    exec ${swaylock} "''${swaylock_args[@]}"
  '';
  swayidleLockscreen = pkgs.writeShellScript "swayidle-lockscreen" ''
    exec ${lib.getExe pkgs.swayidle} -w \
      timeout 300 '${lib.getExe lockScreen}' \
      timeout 600 '${swaymsg} output * power off' \
        resume '${swaymsg} output * power on' \
      before-sleep '${lib.getExe lockScreen}'
  '';
in
{
  options.myHome.desktop.lockscreen = {
    enable = lib.mkEnableOption "Wayland lock screen";
    wallpapers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "${config.home.homeDirectory}/Pictures/图片/walls/nord/a_blue_and_grey_logo.png"
      ];
      description = "Wallpaper candidates for the lock screen. Missing files are ignored.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      lockScreen
      pkgs.swaylock-effects
    ];

    systemd.user.services.lock-screen = {
      Unit = {
        Description = "Swaylock screen locker";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };

      Service = {
        # swaylock --daemonize only returns after the lock surface is ready, so
        # before-sleep cannot race ahead of the screen lock.
        Type = "forking";
        ExecStart = "${runLockScreen}";
        TimeoutStartSec = 15;
      };
    };

    systemd.user.services.swayidle-lockscreen = {
      Unit = {
        Description = "Sway idle lock screen";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };

      Service = {
        ExecStart = "${swayidleLockscreen}";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}
