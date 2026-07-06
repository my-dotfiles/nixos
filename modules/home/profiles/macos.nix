{ ... }:

{
  imports = [
    ../core/session.nix
    ../core/shell.nix
    ../core/xdg.nix
    ../cli/fish.nix
    ../cli/git.nix
    ../cli/github.nix
    ../cli/ghostty.nix
    ../cli/prompt.nix
    ../cli/ssh.nix
    ../cli/terminal.nix
    ../cli/htop.nix
    ../cli/lazygit.nix
    ../cli/tmux.nix
    ../cli/glow.nix
    ../cli/yazi.nix
    ../development/editor.nix
    ../development/emacs.nix
    ../development/tools.nix
    ../development/codex.nix
    ../desktop/fonts.nix
  ];

  myHome.core.session.enable = true;
  myHome.core.shell.enable = true;
  myHome.core.xdg.enable = true;

  myHome.cli.fish = {
    enable = true;
    setSessionShell = true;
  };
  myHome.cli.git = {
    enable = true;
    userName = "yurikon";
    userEmail = "h6606797@gmail.com";
  };
  myHome.cli.github.enable = true;
  myHome.cli.ghostty.enable = true;
  myHome.cli.prompt.enable = true;
  myHome.cli.ssh.enable = true;
  myHome.cli.terminal.enable = true;
  myHome.cli.htop.enable = true;
  myHome.cli.lazygit.enable = true;
  myHome.cli.tmux.enable = true;
  myHome.cli.glow.enable = true;
  myHome.cli.yazi.enable = true;

  myHome.development.editor.enable = true;
  myHome.development.emacs = {
    enable = true;
    enableMail = false;
  };
  myHome.development.tools.enable = true;
  myHome.development.codex.enable = true;

  myHome.desktop.fonts.enable = true;

  targets.darwin.copyApps = {
    enable = true;
    directory = "Applications/Home Manager Apps";
  };
}
