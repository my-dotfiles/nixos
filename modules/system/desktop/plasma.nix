{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.plasma;
in
{
  options.mySystem.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma desktop system integration";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.mySystem.desktop.niri.enable;
        message = "Only one display-manager-owning desktop stack should be enabled: disable mySystem.desktop.niri when enabling Plasma.";
      }
    ];

    services = {
      desktopManager.plasma6.enable = true;

      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        defaultSession = lib.mkDefault "plasma";
      };

      greetd.enable = lib.mkForce false;
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };

    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.ark
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kcolorchooser
      kdePackages.konsole
      kdePackages.okular
      kdePackages.spectacle
      wl-clipboard
    ];
  };
}
