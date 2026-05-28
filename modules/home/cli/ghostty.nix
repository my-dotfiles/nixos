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
        background-blur-radius = 0;
        bold-is-bright = false;
        confirm-close-surface = false;
        cursor-style = "bar";
        font-family = "Maple Mono NF CN";
        font-size = 12;
        gtk-single-instance = true;
        mouse-hide-while-typing = true;
        quick-terminal-position = "center";
        shell-integration = "detect";
        term = "xterm-direct";
        title = "Ghostty";
        unfocused-split-opacity = 0.5;
        wait-after-command = false;
        window-height = 32;
        window-save-state = "always";
        window-theme = "dark";
        window-width = 110;
        theme = "Gruvbox Material";
      };
    };
  };
}
