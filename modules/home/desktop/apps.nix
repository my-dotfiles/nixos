{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.apps;
  optionalPkg =
    name:
    let
      value = lib.attrByPath [ name ] null pkgs;
    in
    lib.optional (value != null) value;
in
{
  options.myHome.desktop.apps.enable = lib.mkEnableOption "desktop applications";

  config = lib.mkIf cfg.enable {
    home.packages =
      # optionalPkg "bitwarden-desktop"
      optionalPkg "file-roller"
      ++ optionalPkg "gnome-calculator"
      ++ optionalPkg "gnome-calendar"
      ++ optionalPkg "gnome-disk-utility"
      ++ optionalPkg "gnome-system-monitor"
      ++ optionalPkg "libreoffice-fresh"
      ++ optionalPkg "loupe"
      ++ optionalPkg "mediaelch"
      ++ optionalPkg "networkmanagerapplet"
      ++ optionalPkg "pavucontrol"
      ++ optionalPkg "papers"
      ++ optionalPkg "qutebrowser"
      ++ optionalPkg "snapshot"
      ++ optionalPkg "decibels"
      ++ optionalPkg "showtime"
      ++ optionalPkg "mission-center"
      ++ optionalPkg "thunderbird"
      ++ optionalPkg "thunar"
      ++ optionalPkg "zotero";
  };
}
