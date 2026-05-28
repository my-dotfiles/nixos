{ config, lib, ... }:

let
  cfg = config.myHome.cli.tmux;
in
{
  options.myHome.cli.tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      mouse = true;
      historyLimit = 100000;
      keyMode = "vi";
      terminal = "tmux-256color";
      extraConfig = ''
        set -g set-titles on
        set -g set-titles-string '#S:#W'
        set -as terminal-features ",*.RGB"
        set -g status-position bottom
        set -g status-interval 1
        set -g status-left "#S "
        set -g status-right "#H | %Y-%m-%d | %H:%M "
        set -g pane-border-style "fg=#45475a"
        set -g pane-active-border-style "fg=#89b4fa"
        set -g set-clipboard on
        set -g allow-passthrough on
        set -ag update-environment "SSH_TTY"
      '';
    };
  };
}
