{ ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../../modules/system/profiles/workstation.nix
  ];

  networking.hostName = "nixos";
  system.stateVersion = "26.05";
}
