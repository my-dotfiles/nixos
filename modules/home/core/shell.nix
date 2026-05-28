{ config, lib, ... }:

let
  cfg = config.myHome.core.shell;
in
{
  options.myHome.core.shell.enable = lib.mkEnableOption "fallback bash shell";

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
    };
  };
}
