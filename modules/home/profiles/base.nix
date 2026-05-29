{ ... }:

{
  imports = [
    ../core/session.nix
    ../core/shell.nix
    ../core/xdg.nix
    ../cli/fish.nix
    ../cli/git.nix
    ../cli/github.nix
    ../cli/prompt.nix
    ../cli/ssh.nix
    ../cli/terminal.nix
    ../cli/ghostty.nix
    ../cli/htop.nix
    ../cli/lazygit.nix
    ../cli/tmux.nix
    ../cli/glow.nix
    ../cli/yazi.nix
    ../development/editor.nix
    ../development/emacs.nix
    ../development/tools.nix
    ../development/codex.nix
    ../desktop/apps.nix
    ../desktop/fonts.nix
    ../desktop/fcitx5.nix
    ../desktop/mime.nix
    ../desktop/mpv.nix
    ../desktop/niri.nix
    ../secrets/local-files.nix
  ];
}
