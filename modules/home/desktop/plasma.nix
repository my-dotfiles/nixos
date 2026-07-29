{
  config,
  lib,
  ...
}:

let
  cfg = config.myHome.desktop.plasma;
in
{
  options.myHome.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma user configuration";

  config = lib.mkIf cfg.enable {
    xdg.configFile."kxkbrc" = {
      force = true;
      text = ''
        [Layout]
        DisplayNames=
        LayoutList=us
        LayoutLoopCount=-1
        Model=pc105
        Options=
        ResetOldOptions=true
        Use=true
        VariantList=
      '';
    };
  };
}
