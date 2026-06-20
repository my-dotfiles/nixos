{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.lockscreen;
  wallpaper = "${config.home.homeDirectory}/Pictures/图片/walls/abstract/a_blue_and_orange_background.jpg";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  lockScreen = pkgs.writeShellScriptBin "lock-screen" ''
    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
    lock_file="$runtime_dir/lock-screen.lock"

    exec 9>"$lock_file"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      exit 0
    fi

    if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -x swaylock >/dev/null; then
      exit 0
    fi

    swaylock_args=(
      --ignore-empty-password
      --show-failed-attempts
      --indicator
      --clock
      --timestr "%H:%M"
      --datestr "%A, %Y-%m-%d"
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
      --effect-vignette "0.35:0.35"
      --fade-in 0.2
    )

    if [ -f "${wallpaper}" ]; then
      swaylock_args+=(--image "${wallpaper}" --scaling fill)
    else
      swaylock_args+=(--screenshots --effect-blur "8x5")
    fi

    exec ${lib.getExe pkgs.swaylock-effects} "''${swaylock_args[@]}"
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
  options.myHome.desktop.lockscreen.enable = lib.mkEnableOption "swaylock lock screen";

  config = lib.mkIf cfg.enable {
    home.packages = [ lockScreen ];

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
