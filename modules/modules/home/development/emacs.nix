{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.develop.emacs;
in
{
  options.myHome.develop.emacs.enable = lib.mkEnableOption "Emacs configuration";
  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
    };
    home.packages = with pkgs; [
      ripgrep
      fd
      imagemagick
      sqlite
      pandoc
    ];
  };
}
