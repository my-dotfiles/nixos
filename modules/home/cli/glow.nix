{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.glow;
in
{
  options.myHome.cli.glow.enable = lib.mkEnableOption "glow markdown previewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.glow ];

    xdg.configFile."glow/glow.yml".text = ''
      style: "auto"
      mouse: false
      pager: false
      width: 80
      all: false
    '';
  };
}
