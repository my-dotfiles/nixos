{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.cursor;
in
{
  options.myHome.desktop.cursor.enable = lib.mkEnableOption "desktop cursor theme";

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };
}
