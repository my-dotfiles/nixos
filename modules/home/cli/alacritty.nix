{ config, lib, ... }:

let
  cfg = config.myHome.cli.alacritty;
  ctrlComma = builtins.fromJSON ''"\u001b[1;5u"'';
in
{
  options.myHome.cli.alacritty.enable = lib.mkEnableOption "Alacritty terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        window.blur = true;
        window.opacity = 0.95;
        font = {
          size = 13;
          normal.family = "Iosevka Nerd Font Mono";
          offset.y = 1;
        };
        keyboard.bindings = [
          {
            key = "Comma";
            mods = "Control";
            chars = ctrlComma;
          }
        ];
      };
    };

    home.sessionVariables.TERMINAL = "alacritty";
  };
}
