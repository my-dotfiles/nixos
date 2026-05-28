{ config, pkgs, ... }:

{
  home.username = "yurikon";
  home.homeDirectory = "/home/yurikon";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    fzf
  ];
}
