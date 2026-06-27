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
      optionalPkg "libreoffice-fresh"
      ++ optionalPkg "mediaelch"
      ++ optionalPkg "qutebrowser"
      ++ optionalPkg "thunderbird"
      ++ optionalPkg "zotero"
      ++ optionalPkg "prismlauncher";
  };
}
