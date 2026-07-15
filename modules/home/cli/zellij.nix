{ config, lib, ... }:

let
  cfg = config.myHome.cli.zellij;
in
{
  options.myHome.cli.zellij.enable = lib.mkEnableOption "Zellij terminal workspace";

  config = lib.mkIf cfg.enable {
    programs.zellij.enable = true;

    xdg.configFile."zellij/config.kdl".source = ./zellij/config.kdl;
  };
}
