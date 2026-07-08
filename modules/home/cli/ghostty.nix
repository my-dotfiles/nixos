{ config, lib, ... }:

let
  cfg = config.myHome.cli.ghostty;
in
{
  options.myHome.cli.ghostty.enable = lib.mkEnableOption "Ghostty terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        adjust-cell-height = "10%";
        background-opacity = 1.0;
        bold-is-bright = true;
        confirm-close-surface = false;
        cursor-style = "block";
        cursor-style-blink = true;
        font-family = "Iosevka Nerd Font Mono";
        font-style = "Medium";
        font-style-italic = "Medium Italic";
        font-size = 13;
        gtk-single-instance = true;
        keybind = [ "ctrl+,=unbind" ];
        mouse-hide-while-typing = true;
        quick-terminal-position = "center";
        shell-integration = "detect";
        term = "xterm-direct";
        unfocused-split-opacity = 0.5;
        wait-after-command = false;
        window-height = 32;
        window-save-state = "always";
        window-theme = "dark";
        window-width = 110;
        background = "#181818";
        foreground = "#d8d8d8";
        palette = [
          "0=#181818"
          "1=#ac4242"
          "2=#90a959"
          "3=#f4bf75"
          "4=#6a9fb5"
          "5=#aa759f"
          "6=#75b5aa"
          "7=#d8d8d8"
          "8=#6b6b6b"
          "9=#c55555"
          "10=#aac474"
          "11=#feca88"
          "12=#82b8c8"
          "13=#c28cb8"
          "14=#93d3c3"
          "15=#f8f8f8"
        ];
      };
    };

    home.sessionVariables.TERMINAL = "ghostty";
  };
}
