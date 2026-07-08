{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.niri;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.mySystem.desktop.niri.enable = lib.mkEnableOption "Niri desktop system integration";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.desktop.plasma.enable;
        message = "Only one display-manager-owning desktop stack should be enabled: disable mySystem.desktop.plasma when enabling Niri.";
      }
      {
        assertion = !config.mySystem.desktop.sway.enable;
        message = "Only one greetd-owning Wayland compositor should be enabled: disable mySystem.desktop.sway when enabling Niri.";
      }
    ];

    programs.niri.enable = true;

    services = {
      greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd niri-session";
      };
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };

    hardware.bluetooth.enable = true;
    environment.systemPackages =
      (with pkgs; [
        niri
        xwayland-satellite
        wl-clipboard
        grim
        slurp
        swappy
        brightnessctl
        playerctl
        fuzzel
        ghostty
        swayidle
        swaylock
        mako
      ])
      ++ [
        inputs.noctalia.packages.${system}.default
      ];
  };
}
