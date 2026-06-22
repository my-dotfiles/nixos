{ config, lib, ... }:

let
  cfg = config.myHome.cli.alacritty;
in
{
  options.myHome.cli.alacritty.enable = lib.mkEnableOption "Alacritty terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        env.WINIT_UNIX_BACKEND = "wayland";
        window.blur = true;
        window.opacity = 0.95;
        font = {
          size = 13;
          normal.family = "Iosevka Nerd Font Mono";
          offset.y = 1;
        };
      };
    };

    home.sessionVariables.TERMINAL = "alacritty";
  };
}
