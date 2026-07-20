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
      nixGc.enable = true;
      packages.enable = true;
      swap = {
        enable = true;
        device = "/home/.swapfile";
        sizeMiB = 16 * 1024;
        swappiness = 20;
        zramMemoryPercent = 25;
      };
      users.enable = true;
    };

    desktop.niri.enable = false;
    desktop.plasma.enable = false;
    desktop.sway.enable = true;
    desktop.thunar.enable = true;
    desktop.steam.enable = true;

    services = {
      docker.enable = true;
      flatpak.enable = true;
      jellyfin = {
        enable = true;
        autoStart = false;
      };
      libvirt.enable = true;
      openssh.enable = true;
      pipewire.enable = true;
      printing.enable = true;
      proxy.enable = true;
      scanning.enable = true;
      tailscale.enable = true;
      usbmuxd.enable = true;
    };
  };

  services.displayManager.defaultSession = "sway";
}
