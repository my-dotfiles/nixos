{ ... }:

{
  imports = [
    ./modules/home/profiles/workstation.nix
  ];

  home.username = "yurikon";
  home.homeDirectory = "/home/yurikon";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
