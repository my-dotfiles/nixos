{ ... }:

{
  imports = [
    ./base.nix
    ../desktop/niri.nix
    ../desktop/plasma.nix
    ../desktop/sway.nix
    ../desktop/steam.nix
  ];

  mySystem = {
    core = {
      boot.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      packages.enable = true;
      users.enable = true;
    };

    desktop.niri.enable = false;
    desktop.plasma.enable = true;
    desktop.sway.enable = false;
    desktop.thunar.enable = false;
    desktop.steam.enable = true;

    services = {
      docker.enable = true;
      jellyfin.enable = true;
      openssh.enable = true;
      pipewire.enable = true;
      printing.enable = true;
      proxy.enable = true;
      tailscale.enable = true;
      usbmuxd.enable = true;
    };
  };
}
