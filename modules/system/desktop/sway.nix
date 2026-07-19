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
    assertions = [
      {
        assertion = !config.mySystem.desktop.niri.enable;
        message = "Only one greetd-owning Wayland compositor should be enabled: disable mySystem.desktop.niri when enabling Sway.";
      }
      {
        assertion = !config.mySystem.desktop.plasma.enable;
        message = "Only one display-manager-owning desktop stack should be enabled: disable mySystem.desktop.plasma when enabling Sway.";
      }
    ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      # This will cause parse error
      # extraSessionCommands = ''
      #   export WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:00:02.0-card
      # '';
    };
    programs.dconf.enable = true;

    services = {
      greetd = lib.mkIf (!config.services.displayManager.sddm.enable) {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd ${lib.getExe config.programs.sway.package}";
      };
      upower = {
        enable = true;
        usePercentageForPolicy = true;
        percentageLow = 20;
        percentageCritical = 7;
        percentageAction = 3;
        criticalPowerAction = "PowerOff";
      };
      power-profiles-daemon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
      gnome.gnome-keyring.enable = true;
      blueman.enable = true;
      logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandleLidSwitchDocked = "ignore";
        HandlePowerKey = "poweroff";
      };
    };

    hardware.bluetooth.enable = true;

    security.polkit.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
    security.pam.services.swaylock = { };

    # Both built-in and external displays are wired to the Intel GPU. Keep the
    # compositor off the NVIDIA DRM device while retaining PRIME render offload.
    # This will cause parse error
    # environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card";

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
      config.sway = {
        default = lib.mkForce [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
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
      polkit_gnome
      wev
    ];
  };
}
