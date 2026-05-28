{ ... }:

{
  imports = [
    ./base.nix
  ];

  myHome.core.session.enable = true;
  myHome.core.shell.enable = true;
  myHome.core.xdg.enable = true;

  myHome.cli.fish.enable = true;
  myHome.cli.git = {
    enable = true;
    userName = "yurikon";
    userEmail = "h6606797@gmail.com";
  };
  myHome.cli.prompt.enable = true;
  myHome.cli.terminal.enable = true;
  myHome.cli.ghostty.enable = true;
  myHome.cli.lazygit.enable = true;
  myHome.cli.tmux.enable = true;
  myHome.cli.glow.enable = true;

  myHome.development.emacs.enable = true;
  myHome.development.tools.enable = true;
  myHome.development.codex.enable = true;

  myHome.desktop.apps.enable = true;
  myHome.desktop.fonts.enable = true;
  myHome.desktop.fcitx5.enable = true;
  myHome.desktop.mime.enable = true;
  myHome.desktop.niri.enable = true;

  myHome.secrets.localFiles.enable = true;
}
