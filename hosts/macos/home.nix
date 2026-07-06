{ ... }:

{
  imports = [
    ../../modules/home/profiles/macos.nix
  ];

  home.username = "yurikon";
  home.homeDirectory = "/Users/yurikon";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
