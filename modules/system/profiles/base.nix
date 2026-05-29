{ ... }:

{
  imports = [
    ../core/boot.nix
    ../core/locale.nix
    ../core/networking.nix
    ../core/nix.nix
    ../core/packages.nix
    ../core/users.nix
    ../desktop/thunar.nix
    ../services/jellyfin.nix
    ../services/openssh.nix
    ../services/pipewire.nix
    ../services/printing.nix
    ../services/proxy.nix
    ../services/tailscale.nix
    ../services/usbmuxd.nix
  ];
}
