{ ... }:

{
  imports = [
    ../core/boot.nix
    ../core/locale.nix
    ../core/networking.nix
    ../core/nix.nix
    ../core/nix-gc.nix
    ../core/packages.nix
    ../core/swap.nix
    ../core/users.nix
    ../desktop/thunar.nix
    ../services/docker.nix
    ../services/flatpak.nix
    ../services/jellyfin.nix
    ../services/libvirt.nix
    ../services/mihomo.nix
    ../services/openssh.nix
    ../services/pipewire.nix
    ../services/printing.nix
    ../services/proxy.nix
    ../services/scanning.nix
    ../services/tailscale.nix
    ../services/usbmuxd.nix
  ];
}
