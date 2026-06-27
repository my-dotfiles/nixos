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
      greetd = lib.mkIf (!config.services.displayManager.sddm.enable) {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd sway";
      };
      upower.enable = true;
      power-profiles-daemon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };

    hardware.bluetooth.enable = true;

    security.polkit.enable = true;
    security.pam.services.swaylock = { };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    environment.systemPackages = with pkgs; [
      sway
      swaybg
      swayidle
      swaylock-effects
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
