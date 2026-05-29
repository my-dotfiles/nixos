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
      matchBlocks = {
        macos = {
          hostname = "100.120.108.67";
          user = "yurikon";
          extraOptions = {
            RequestTTY = "yes";
            RemoteCommand = "TERM=xterm-256color exec $SHELL -l";
          };
        };
      };
    };
  };
}
