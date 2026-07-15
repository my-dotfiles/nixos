{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.cli.alacritty;
in
{
  options.myHome.cli.alacritty.enable = lib.mkEnableOption "Alacritty terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      theme = "base16_default_dark";
      settings = {
        env.WINIT_UNIX_BACKEND = "wayland";
        terminal.shell = {
          program = lib.getExe pkgs.zellij;
          args = [
            "attach"
            "--create"
            "main"
          ];
        };
        font = {
          size = 13;
          normal = {
            family = "JetBrainsMono Nerd Font Mono";
            style = "Medium";
          };
        };
        mouse.hide_when_typing = true;
      };
    };

    home.sessionVariables.TERMINAL = "alacritty";
  };
}
