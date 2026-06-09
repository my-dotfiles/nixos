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
  myHome.cli.github.enable = true;
  myHome.cli.prompt.enable = true;
  myHome.cli.ssh.enable = true;
  myHome.cli.terminal.enable = true;
  myHome.cli.alacritty.enable = true;
  myHome.cli.htop.enable = true;
  myHome.cli.lazygit.enable = true;
  myHome.cli.tmux.enable = true;
  myHome.cli.glow.enable = true;
  myHome.cli.yazi.enable = true;

  myHome.development.emacs.enable = true;
  myHome.development.tools.enable = true;
  myHome.development.codex.enable = true;
  myHome.development.pi.enable = true;

  myHome.desktop.apps.enable = true;
  myHome.desktop.fonts.enable = true;
  myHome.desktop.fcitx5.enable = true;
  myHome.desktop.lockscreen.enable = true;
  myHome.desktop.mime.enable = true;
  myHome.desktop.mpv.enable = true;
  myHome.desktop.niri.enable = true;

  myHome.services.rclone.enable = true;

  myHome.secrets.sops.enable = true;
  myHome.secrets.localFiles.enable = true;

  myHome.communication.mail.enable = true;
}
