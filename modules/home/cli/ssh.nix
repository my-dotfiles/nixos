{ config, lib, ... }:

let
  cfg = config.myHome.cli.ssh;
in
{
  options.myHome.cli.ssh.enable = lib.mkEnableOption "OpenSSH client configuration";

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          hostname = "ssh.github.com";
          user = "git";
          port = 443;
          identityFile = [ "~/.ssh/id_ed25519_new" ];
          identitiesOnly = true;
          serverAliveInterval = 30;
          serverAliveCountMax = 3;
        };

        macos = {
          hostname = "100.120.108.67";
          user = "yurikon";
          RequestTTY = "yes";
          RemoteCommand = "TERM=xterm-256color exec $SHELL -l";
        };
      };
    };
  };
}
