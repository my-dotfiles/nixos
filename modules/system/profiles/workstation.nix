{ ... }:

{
  imports = [
    ./base.nix
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

    desktop.sway.enable = true;
    desktop.thunar.enable = true;
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
