{ config, pkgs, ... }:

{
  imports = [./modules/home/development/emacs.nix];
  myHome.development.emacs.enable = true;
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

    flclash
  ];
}
