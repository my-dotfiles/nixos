{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.ghostty;
  fish = "${pkgs.fish}/bin/fish";
  ghosttyConfig = ''
    command = ${fish} --login
  '';
in
{
  options.myHome.cli.ghostty.enable = lib.mkEnableOption "Ghostty terminal configuration";

  config = lib.mkIf cfg.enable {
    xdg.configFile."ghostty/config".text = ghosttyConfig;

    home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ghosttyConfig;
  };
}
