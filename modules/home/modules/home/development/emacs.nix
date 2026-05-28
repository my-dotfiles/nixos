{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.development.emacs;
in
{
  options.myHome.development.emacs.enable =
    lib.mkEnableOption "Emacs configuration";

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
