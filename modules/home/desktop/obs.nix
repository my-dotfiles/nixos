{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.desktop.obs;
in
{
  options.myHome.desktop.obs.enable = lib.mkEnableOption "OBS Studio live streaming";

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    };
  };
}
