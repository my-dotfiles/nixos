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
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.udisks2.enable = true;
    security.polkit.enable = true;
  };
}
