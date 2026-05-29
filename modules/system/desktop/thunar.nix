{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.desktop.thunar;
in
{
  options.mySystem.desktop.thunar.enable = lib.mkEnableOption "Thunar file manager integration";

  config = lib.mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
