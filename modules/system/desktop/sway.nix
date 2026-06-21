{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.sway;
in
{
  options.mySystem.desktop.sway.enable = lib.mkEnableOption "Sway desktop system integration";

  config = lib.mkIf cfg.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    services = {
      greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd sway";
      };
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };

    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      sway
      swaybg
      swayidle
      swaylock
      wl-clipboard
      grim
      slurp
      swappy
      brightnessctl
      playerctl
      fuzzel
      alacritty
      mako
      wev
    ];
  };
}
