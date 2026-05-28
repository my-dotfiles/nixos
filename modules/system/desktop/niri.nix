{ pkgs, ... }:

{
  program.niri.enable = true;
  services.displayManager.gdm.enable = true;
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    niri
    xwayland-satellite
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    fuzzel
    ghostty
  ];
}
