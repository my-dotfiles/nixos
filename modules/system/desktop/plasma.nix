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
      gvfs.enable = true;
      udisks2.enable = true;

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    hardware.bluetooth.enable = true;
    hardware.sane.enable = true;

    programs.kdeconnect.enable = true;
    programs.kde-pim = {
      enable = true;
      merkuro = true;
      kmail = false;
      kontact = false;
    };

    security.polkit.enable = true;

    xdg.portal = {
      enable = true;
      config.kde = {
        default = [ "kde" ];
        "org.freedesktop.impl.portal.Notification" = [ "plasmanotify" ];
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
        "org.freedesktop.impl.portal.Settings" = [
          "kde"
          "gtk"
        ];
      };
      xdgOpenUsePortal = true;
    };

    environment.systemPackages = with pkgs; [
      # Theme compatibility.
      kdePackages.oxygen
      kdePackages.oxygen-icons
      kdePackages.oxygen-sounds

      # Plasma shell integration.
      kdePackages.kde-cli-tools
      kdePackages.kde-gtk-config
      kdePackages.kdialog
      kdePackages.kgamma
      kdePackages.kinfocenter
      kdePackages.kscreen
      kdePackages.kwalletmanager
      kdePackages.plasma-browser-integration
      kdePackages.plasma-nm
      kdePackages.plasma-pa
      kdePackages.print-manager
      kdePackages.systemsettings

      # Online accounts and Google Calendar integration.
      kdePackages.kaccounts-integration
      kdePackages.kaccounts-providers
      kdePackages.kio-gdrive
      kdePackages.signon-kwallet-extension

      # Core Plasma applications.
      kdePackages.ark
      kdePackages.dolphin
      kdePackages.discover
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kcolorchooser
      kdePackages.konsole
      kdePackages.okular
      kdePackages.spectacle

      # File manager and KIO integration.
      kdePackages.dolphin-plugins
      kdePackages.ffmpegthumbs
      kdePackages.kfind
      kdePackages.kio-admin
      kdePackages.kio-extras
      kdePackages.kio-fuse

      # System maintenance and diagnostics.
      kdePackages.filelight
      kdePackages.isoimagewriter
      kdePackages.partitionmanager
      kdePackages.plasma-disks
      kdePackages.plasma-systemmonitor

      # Daily desktop applications.
      kdePackages.elisa
      kdePackages.gwenview
      kdePackages.kolourpaint
      kdePackages.kamera
      kdePackages.krdc
      kdePackages.skanpage
      kdePackages.yakuake
      haruna

      wl-clipboard
    ];
  };
}
